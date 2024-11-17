/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package Application

import Schemas.VisitSchema
import org.apache.flink.api.common.eventtime.WatermarkStrategy
import org.apache.flink.api.common.functions.{FlatMapFunction, MapFunction}
import org.apache.flink.api.java.io.TextInputFormat
import org.apache.flink.connector.file.src.FileSource
import org.apache.flink.connector.file.src.reader.TextLineFormat
import org.apache.flink.connector.jdbc.{JdbcConnectionOptions, JdbcExecutionOptions, JdbcSink, JdbcStatementBuilder}
import org.apache.flink.core.fs.Path
import org.apache.flink.streaming.api.functions.source.FileProcessingMode
import org.apache.flink.streaming.api.scala.{DataStream, StreamExecutionEnvironment, createTypeInformation}
import org.apache.flink.util.Collector

import java.sql.{PreparedStatement, Timestamp}
import java.time.Duration


object VisitMainApp {

  //Ingestion using SQS
//  https://medium.com/datareply/event-driven-file-ingestion-using-flink-source-api-cfe45e43f88b

  // Configuration Constants
  val S3_VISITS_PATH: String = "s3://fsm-bucket-kaloger/visits/"
  val DB_URL: String = "jdbc:postgresql://localhost:5432/productDb"
  val DB_USER: String = "admin"
  val DB_PASSWORD: String = "admin1234"
  val DB_DRIVER: String = "org.postgresql.Driver"

  @throws[Exception]
  def main(args: Array[String]): Unit = {

    val env = StreamExecutionEnvironment.getExecutionEnvironment

    //Read once file and close once done
//    val sourcePath = FileSource.forRecordStreamFormat(new TextLineFormat(), new Path(S3_VISITS_PATH)).build()
//    val sourceExec: DataStream[String] = env.fromSource(sourcePath, WatermarkStrategy.forMonotonousTimestamps(), "S3VisitsSource")

    val sourceExec = env.readFile(new TextInputFormat(new Path(S3_VISITS_PATH)),
                                  S3_VISITS_PATH,
                                  FileProcessingMode.PROCESS_CONTINUOUSLY,
                                  Duration.ofSeconds(10).toMillis())  //Adjust to more periodically. For testing purposes

    val flattenedVisitStream = sourceExec.flatMap(new FlatMapFunction[String, VisitSchema]{

      override def flatMap(input: String, collector: Collector[VisitSchema]): Unit = {

        val stripVisits: String = input.stripPrefix("{").stripSuffix("}")
        val pairs: Array[String] = stripVisits.split(",")

        val dataMap = pairs.map { pair =>
          // This regex does not take into account : into quotes
          val Array(key, value) = pair.split("(?!\\B\"[^\"]*):(?![^\"]*\"\\B)", 2).map(_.trim.replace("\"", ""))
          (key, value)
        }.toMap

        dataMap("engineer_note").split(" ").foreach(x => collector.collect(VisitSchema(
          task_id = dataMap("task_id").replace("TASK","").toInt,
          node_id = dataMap("node_id").replace("NODE","").toInt,
          visit_id = dataMap("visit_id").toInt,
          visit_date = Timestamp.valueOf(dataMap("visit_date:")),
          original_reported_date = Timestamp.valueOf(dataMap("original_reported_date")),
          node_age = dataMap("node_age").toInt,
          node_type = dataMap("node_type").replace("TYPE","").toInt,
          task_type = dataMap("task_type").replace("TASK","").toInt,
          engineer_skill_level = dataMap("engineer_skill_level").replace("LEVEL","").toInt,
          engineer_note = x.toInt,
          outcome = dataMap("outcome"))))
      }
    })



    flattenedVisitStream.print()
    flattenedVisitStream.addSink(JdbcSink.sink[VisitSchema]("""
                                          |INSERT INTO VISITS (task_id, node_id, visit_id, visit_date, original_reported_date,
                                          | node_age, node_type, task_type, engineer_skill_level, engineer_note, outcome)
                                          |VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                                          |""".stripMargin, new JdbcStatementBuilder[VisitSchema] { // the way to expand the wildcards with actual values


      override def accept(statement: PreparedStatement, fsm: VisitSchema): Unit = {
        statement.setInt(1, fsm.task_id)
        statement.setInt(2, fsm.node_id)
        statement.setInt(3, fsm.visit_id)
        statement.setTimestamp(4, fsm.visit_date)
        statement.setTimestamp(5, fsm.original_reported_date)
        statement.setInt(6, fsm.node_age)
        statement.setInt(7, fsm.node_type)
        statement.setInt(8, fsm.task_type)
        statement.setInt(9, fsm.engineer_skill_level)
        statement.setInt(10, fsm.engineer_note)
        statement.setString(11, fsm.outcome)
      }
    }, JdbcExecutionOptions.builder
                          .withBatchSize(1000)
                          .withBatchIntervalMs(200)
                          .withMaxRetries(5).build,
      new JdbcConnectionOptions.JdbcConnectionOptionsBuilder()
        .withUrl(DB_URL)
        .withDriverName(DB_DRIVER)
        .withUsername(DB_USER)
        .withPassword(DB_PASSWORD)
        .build()
    ))


    env.execute("VisitMainApp")
  }

}