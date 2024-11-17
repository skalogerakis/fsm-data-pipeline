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

import Schemas.NetworkSchema
import org.apache.flink.api.common.eventtime.WatermarkStrategy
import org.apache.flink.api.common.functions.{FlatMapFunction, MapFunction}
import org.apache.flink.connector.file.src.FileSource
import org.apache.flink.connector.file.src.reader.TextLineFormat
import org.apache.flink.connector.jdbc.table.JdbcConnectorOptions
import org.apache.flink.connector.jdbc.{JdbcConnectionOptions, JdbcExecutionOptions, JdbcSink, JdbcStatementBuilder}
import org.apache.flink.core.fs.Path
import org.apache.flink.streaming.api.scala.{DataStream, OutputTag, StreamExecutionEnvironment, createTypeInformation}
import org.apache.flink.util.Collector
import org.h2.jdbcx.JdbcDataSource

import java.sql.PreparedStatement


object NetworkMainApp {

  // Configuration Constants
  val S3_NETWORK_PATH: String = "s3://fsm-bucket-kaloger/network/"
  val DB_URL: String = "jdbc:postgresql://localhost:5432/productDb"
  val DB_USER: String = "admin"
  val DB_PASSWORD: String = "admin1234"
  val DB_DRIVER: String = "org.postgresql.Driver"

  @throws[Exception]
  def main(args: Array[String]): Unit = {

    val env = StreamExecutionEnvironment.getExecutionEnvironment

    // Since this data is supposed to be static when don't need to execute and keep waiting for others to arrive
    val networkSource = FileSource.forRecordStreamFormat(new TextLineFormat(), new Path(S3_NETWORK_PATH)).build()
    val sourceExec: DataStream[String] = env.fromSource(networkSource, WatermarkStrategy.forMonotonousTimestamps(), "S3NetworkSource")

    val formattedNetworkStream: DataStream[NetworkSchema] = sourceExec.flatMap(new FlatMapFunction[String, NetworkSchema]{

      override def flatMap(input: String, collector: Collector[NetworkSchema]): Unit = {
        val nodeArr = input.split(" ").map(_.replace("NODE", "").trim).filter(_.nonEmpty)

        // In case a node does have at least 1 adjacent node don't send anything
        if (nodeArr.size > 1)
          nodeArr.tail.foreach(x => collector.collect(NetworkSchema(node = nodeArr.head.toInt, adj_node = x.toInt)))

      }
    })


    formattedNetworkStream.print()
    formattedNetworkStream.addSink(JdbcSink.sink[NetworkSchema]("""
                                                                |INSERT INTO NETWORK (node, adj_node)
                                                                |VALUES (?, ?)
                                                                |""".stripMargin, new JdbcStatementBuilder[NetworkSchema] { // the way to expand the wildcards with actual values


          override def accept(statement: PreparedStatement, networkSchema: NetworkSchema): Unit = {
            statement.setInt(1, networkSchema.node)
            statement.setInt(2, networkSchema.adj_node)

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


    env.execute("NetworkMainApp")
  }

}