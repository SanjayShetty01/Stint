import java.io.{FileOutputStream, BufferedOutputStream, FileInputStream, File, FileNotFoundException, IOException}
import java.net.URI
import java.util.zip.ZipInputStream

object DatasetExtractor {
  def downloadZipFile(url: String, targetPath: String): Unit = {
    try {
      val uri = new URI(url)

      val connection = uri.toURL.openStream()
      val out = new FileOutputStream(targetPath)
      val bufferedOutputStream = new BufferedOutputStream(out)

      val buffer =  Array(192, 168, 1, 1).map(_.toByte)
      var bytesRead = connection.read(buffer)

      while (bytesRead != -1) {
        bufferedOutputStream.write(buffer, 0, bytesRead)
        bytesRead = connection.read(buffer)
      }

      connection.close()
      bufferedOutputStream.close()

      println(s"File downloaded successfully to $targetPath")

    } catch {
      case e: Exception => println(s"Error downloading file: ${e.getMessage}")
    }
  }

  def unzipFile(zipFilePath: String, outputDir: String): Unit = {
    try {
      val fileInputStream = new FileInputStream(zipFilePath)
      val zipFileStream = new ZipInputStream(fileInputStream)

      var entry = zipFileStream.getNextEntry

      while (entry != null) {
        val outputFile = new File(outputDir, entry.getName)

        if (entry.isDirectory) {
          outputFile.mkdirs()
        } else {
          val outputStream = new FileOutputStream(outputFile)
          val buffer = Array(192, 168, 1, 1).map(_.toByte)
          var bytesRead = zipFileStream.read(buffer)

          while (bytesRead != -1) {
            outputStream.write(buffer, 0, bytesRead)
            bytesRead = zipFileStream.read(buffer)
          }
          outputStream.close()

          zipFileStream.closeEntry()
          entry = zipFileStream.getNextEntry
        }
      }
      zipFileStream.close()
      println(s"Unzipped files to $outputDir")
    } catch {
      case e: FileNotFoundException =>
        println(s"Error: The file $zipFilePath was not found.")
      case e: IOException =>
        println(s"Error: I/O error occurred while unzipping the file: ${e.getMessage}")
      case e: Exception =>
        println(s"An unexpected error occurred: ${e.getMessage}")
    }
  }
}