# KERBEROS.**IO**

[![gitcheese.com](https://s3.amazonaws.com/gitcheese-ui-master/images/badge.svg)](https://www.gitcheese.com/donate/users/1546779/repos/52265945)

[![Kerberos.io - video surveillance](https://kerberos.io/images/kerberos.png)](https://kerberos.io)

## Why Kerberos.io?

As burgalary is very common, we believe that video surveillance is a **trivial tool** in our daily lifes which helps us to **feel** a little bit more **secure**. Responding to this need, a lot of companies have started developing their own video surveillance software in the past few years.

Nowadays we have a myriad of **expensive** cameras, recorders and software solutions which are mainly **outdated** and **difficult** to install and use. Kerberos.io's goal is to solve these problems and to provide every human being in this world to have its own **ecological**, **affordable**, **easy-to-use** and **innovative** surveillance solution.

## Introduction

[Kerberos.io](https://kerberos.io) is a **low-budget** video surveillance solution, that uses computer vision algorithms to detect changes, and that can trigger other devices. [Kerberos.io](https://kerberos.io) is open source so everyone can customize the source code to its needs and share it with the community. When deployed on the Raspberry Pi, it has a **green footprint** and it's **easy to install**; you only need to transfer the [Kerberos.io OS (KIOS)](https://doc.kerberos.io/2.0/installation/KiOS) to your SD card and that's it.

Use your mobile phone, tablet or PC to keep an eye on your property. View the images taken by [Kerberos.io](https://kerberos.io) with our responsive and user-friendly web interface. Look at the dashboard to get a graphical overview of the past days. Multiple [Kerberos.io](https://kerberos.io) instances can be installed and can be viewed with only 1 web interface.

# Docker

**!!! For the moment this approach only works for IP cameras, we don't have a cross-platform method to inject a USB camera or Raspberry Pi camera !!!**

A Docker image (x86, ARMv7, ARMv8) is available on [**the Docker Hub**](https://hub.docker.com/u/kerberos/kerberos). Before you can run this image you will have to get [**Docker**](https://docker.com) installed. After the installation you can use **docker run** to get Kerberos.io up and running.

## Run a simple command.

After you've installed docker, you can open a command prompt and type in following command. This will pull the kerberos image and make the web interface available on port 80 and the livestream on port 8889. You can give the container a custom name using the **--name** property.

    $ docker run --name camera1 -p 80:80 -p 8889:8889 -d kerberos/kerberos
    $ docker run --name camera2 -p 81:80 -p 8890:8889 -d kerberos/kerberos
    $ docker run --name camera3 -p 82:80 -p 8891:8889 -d kerberos/kerberos

## Use dockeros (our docker creation tool)

We've created a simple and small tool to auto provision and auto configure Kerberos.io containers. The idea is that you define the different configurations for every camera upfront, and map them to into your docker container (using volumes). The ultimate goal is to have a fully automated and lightning fast way for provisioning your video surveillance environments in just a matter of seconds.

    CAMERA 1 <<== CONTAINER1 <<== environment/cameraconfig1
    CAMERA 2 <<== CONTAINER2 <<== environment/cameraconfig2
    CAMERA 3 <<== CONTAINER2 <<== environment/cameraconfig3

### How to use it?

The tool we've created is a simple bash script which we called **dockeros**, and exposes a couple of methods; discussed below. By defining a couple input parameters, **dockeros** will do all the magic docker commandline for you.
    
    git clone https://github.com/kerberos-io/docker
    cd docker/bin
    ./dockeros.sh {command}

### Commands

    ./dockeros.sh **showall**

List all kerberos.io containers which are created.

    ./dockeros.sh **cleanup**

Remove all kerberos.io containers which were created before.

    ./dockeros.sh **create** {name} {config} {webport} {streamport}

This method requires a couple of arguments, if left blank the arguments will be asked while executing the command.

**name**: This is the name of the container which will be created.

**config**: The configuration which needs to be injected in the container. The configuration files can be found in the **/environments** folder.

**webport**: The port on which the webinterface will be served.

**streamport**: The port on which the livestream will be served.
