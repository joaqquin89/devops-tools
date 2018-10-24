FROM jenkins/jenkins
MAINTAINER Joaquin Jachura Chavez 0.1
USER root
RUN curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" && python get-pip.py
RUN pip install -U ansible
USER jenkins
