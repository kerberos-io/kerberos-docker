#KERBEROS.**IO**

[![Kerberos.io - video surveillance](https://kerberos.io/images/kerberos.png)](https://kerberos.io)

## Why Kerberos.io?

As burgalary is very common, we believe that video surveillance is a **trivial tool** in our daily lifes which helps us to **feel** a little bit more **secure**. Responding to this need, a lot of companies have started developing their own video surveillance software in the past few years.

Nowadays we have a myriad of **expensive** camera's, recorders and software solutions which are mainly **outdated** and **difficult** to install and use. Kerberos.io's goal is to solve these problems and to provide every human being in this world to have its own **ecological**, **affordable**, **easy-to-use** and **innovative** surveillance solution.

## Introduction

[Kerberos.io](http://kerberos.io) is a **low-budget** video surveillance solution, that uses computer vision algorithms to detect changes, and that can trigger other devices. [Kerberos.io](http://kerberos.io) is open source so everyone can customize the source code to its needs and share it with the community. When deployed on the Raspberry Pi, it has a **green footprint** and it's **easy to install**; you only need to transfer the [Kerberos.io OS (KIOS)](https://doc.kerberos.io/2.0/installation/KiOS) to your SD card and that's it.

Use your mobile phone, tablet or PC to keep an eye on your property. View the images taken by [Kerberos.io](http://kerberos.io) with our responsive and user-friendly web interface. Look at the dashboard to get a graphical overview of the past days. Multiple [Kerberos.io](http://kerberos.io) instances can be installed and can be viewed with only 1 web interface.

##Docker

A Docker image is available on the Docker Hub. Before you can run this image you will have to get Docker or Docker-machine (Windows/OSX) installed. After the installation you can use docker-compose to get Kerberos.io up and running. More detailed information can be found here.

### Installation

Create a docker-compose.yml file and following configuration:

    machinery:
        image: kerberos/machinery
        ports:
        - "8888:8888"
    web:
        image: kerberos/web
        ports:
        - "80:80"
        volumes_from:
        
Run following command; this will download the Kerberos.io docker images and configure them properly.

    docker-compose up
        - machinery
