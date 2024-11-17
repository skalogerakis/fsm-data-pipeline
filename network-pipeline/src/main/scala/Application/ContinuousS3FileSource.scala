package Application

import org.apache.flink.streaming.api.functions.source.{RichSourceFunction, SourceFunction}
import software.amazon.awssdk.services.s3.S3Client

import scala.collection.JavaConverters._
import software.amazon.awssdk.services.s3.model._
import scala.collection.convert.ImplicitConversions.`collection asJava`
import scala.collection.immutable.HashSet



class ContinuousS3FileSource (bucketName: String) extends RichSourceFunction[String] {

  @volatile private var isRunning = true
  private val processedFiles: HashSet[String] = new HashSet()

  override def run(ctx: SourceFunction.SourceContext[String]): Unit = {
    val s3 = S3Client.builder().build

    while (isRunning) {
      // List files in S3 bucket
      val listRequest = ListObjectsV2Request.builder().bucket(bucketName).build()
      val s3Objects = s3.listObjectsV2(listRequest).contents().asScala

      // Filter out already processed files
      s3Objects
        .filter(obj => !processedFiles.contains(obj.key()))
        .foreach { obj =>
          processedFiles.add(obj.key())
          print(obj.key())
//          val fileContent = s3.getObjectAsBytes(builder => builder.bucket(bucketName).key(obj.key())).asUtf8String()
//          ctx.collect(fileContent) // Send content downstream
        }
      Thread.sleep(5000) // Poll every 5 seconds
    }
  }

  override def cancel(): Unit = {
    isRunning = false
  }
}
