import java.sql.{Connection, DriverManager}

object DatabaseManager {
  private var connection: Option[Connection] = None

  def initialize(dbPath: String): Unit = {
    val url = s"jdbc:sqlite:$dbPath"
    connection = Some(DriverManager.getConnection(url))
    println("Database initialized!")
  }

  def getConnection: Connection = {
    connection.getOrElse(throw new IllegalStateException("Database not initialized"))
  }

  def close(): Unit = {
    connection.foreach(_.close())
    println("Database connection closed!")
  }
}
