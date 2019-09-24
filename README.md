# Spark Container on Debian

Build Apache Spark Container on Debian buster.


| Software | Version | Comments
| -------- | -------:| ---------
| Java     | 8       | OpenJDK 8 Headless
| Spark    | 2.4.4   |

Spark throws some warning `Illegal reflective access` warning for `java.nio.Bits.unaligned()` when using OpenJDK 11. 
Oracle Java 8 has changed licensing. Now uasage is only allowed for personal use and development. Otherwise a subscription
is needed.  Solution is to use OpenJDK 8 from oldstable. There is a OpenJDK 8 in sid, so in the future we can take it from
stable.

The containers are layered. 
debian_base -> 
  spark_base ->
    spark_master
    spark_worker
    airflow_spark_client 