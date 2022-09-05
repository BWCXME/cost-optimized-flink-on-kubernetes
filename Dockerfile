FROM maven:3.8.6-amazoncorretto-11 AS builder
COPY src/ /home/app/src
COPY pom.xml /home/app/
RUN ls -l /home/app
RUN mvn -f /home/app/pom.xml clean package -Dflink.version=1.13.0

FROM <private_repo_address>/flink:<tag>
RUN mkdir -p $FLINK_HOME/usrlib
COPY --from=builder /home/app/target/aws-kinesis-analytics-java-apps-1.0.jar $FLINK_HOME/usrlib/aws-kinesis-analytics-java-apps-1.0.jar
RUN mkdir $FLINK_HOME/plugins/s3-fs-hadoop
COPY lib/flink-s3-fs-hadoop-1.13.0.jar  $FLINK_HOME/plugins/s3-fs-hadoop/
RUN mkdir /usr/local/java
RUN mkdir /clib
ADD amazon-corretto-11-aarch64-linux-jdk.tar.gz /usr/local/java
RUN ln -s /usr/local/java/amazon-corretto-11.0.16.9.1-linux-aarch64 /usr/local/java/jdk
ENV JAVA_HOME /usr/local/java/jdk
ENV JRE_HOME ${JAVA_HOME}/jre
ENV CLASSPATH .:${JAVA_HOME}/lib:${JRE_HOME}/lib
ENV PATH ${JAVA_HOME}/bin:$PATH

