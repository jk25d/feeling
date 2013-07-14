import scala.language.postfixOps
import java.io._
import scala.collection.immutable.Map
import scala.collection.mutable.Set
import scala.collection.mutable.LinkedList
import collection.JavaConversions._

/* 14-5
object Test extends App{
  def leafSum(l: List[Any] ) : Int = {
    l.map(  
      _ match {
        case x: Int => x
        case x: List[Any] => leafSum(x)
        case _ => 0
      }
    ).sum
  }
  println( leafSum( List(List(3,8),2,List(5)) ) )
}
*/

/* 14-2
object Test extends App{
  def swap(x: Int, y: Int) = {
    (y,x)
  }
  println(swap(1,2))
}
*/

/* 13-03
object Test extends App{
  def removez(l: LinkedList[Int]) = {
    l.filter(_ != 0)
  }
  println( removez(LinkedList(1,0,2,0,3,4)) )
}
*/

/* 13-01
import java.util._
object Test extends App{
  def indexes(s: String) = {
    val m: TreeMap[Char,Set[Int]] = new TreeMap
    for(i <- 0 until s.size){
      if(!(m contains s(i))){
        m(s(i)) = Set[Int]();
      }
      m(s(i)) += i
    }
    m
  }
  println(indexes("Mississipi"))
}
*/

/* 12-10
object Test extends App{
  def unless(cond: => Boolean)(expr: => Unit) = {
    if(!cond) expr
  }
  var i = "asdf"
  unless(i == null){ println(i)}
}
*/

/* 12-8
object Test extends App{
  def correspond(ss: Array[String], is: Array[Int]) = {
    ss.corresponds(is)( _.size == _ )
  }
  println { correspond(Array("asdf","qwe"), Array(4,3)) }
}
*/

/* 12-5
object Test extends App{
  def largest(f: Int => Int, in: Seq[Int]) = {
    in map {f} max
  }
  println { largest(x=>10*x-x*x, 1 to 10) }
}
*/

/* 12-1
object Test extends App{
  def values(f: Int => Int, low: Int, high: Int) = {
    low to high map { x => (x,f(x)) }
  }
  println { values( x => x*x, -5, 5) }
}
*/


/* 10-08
object Test extends App{
  val a = new ByteArrayInputStream("asdf" getBytes) with Bufferable
  var x: Int = _
  while({x = a.read; x != -1}){ println(x) }
}

trait Bufferable{
  this: InputStream =>
    val bin = new BufferedInputStream(this)
    override def read = bin.read
    override def close = bin.close
}
*/

/* 10-04 
object Test extends App{
  println { new CryptoLogger log {"asdf"} }
}

class CryptoLogger(val key : Int = 3){
  def log (s: String) : String = {
    s.map { x => x match {
        case x if x isLower => ('a' + (x-'a'+key)%26).toChar 
        case x if x isUpper => ('A' + (x-'A'+key)%26).toChar
        case x => x
      }
    }
  }
}
*/
