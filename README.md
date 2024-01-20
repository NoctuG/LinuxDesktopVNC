# LinuxRDP 使用指南

这个Dockerfile用于创建一个带有VNC和noVNC的Docker镜像，以便于在Web浏览器中远程访问虚拟桌面。以下是如何使用这个Dockerfile的步骤。

## 前提条件

确保你的系统已经安装了Docker。如果没有，请参照[Docker官方文档](https://docs.docker.com/get-docker/)进行安装。

## 构建Docker镜像

首先，你需要构建Docker镜像。将Dockerfile保存到本地，然后在Dockerfile所在的目录运行以下命令：

```bash
docker build -t vnc-novnc:latest .
```

这将创建一个名为`vnc-novnc`的Docker镜像，标签为`latest`。

## 运行Docker容器

然后，你可以运行一个Docker容器，使用以下命令：

```bash
docker run -d -p 8900:8900 vnc-novnc:latest
```

这将在后台运行一个Docker容器，并将容器的8900端口映射到主机的8900端口。

## 访问虚拟桌面

最后，你可以在Web浏览器中访问`http://localhost:8900`，以远程访问虚拟桌面。

请注意，VNC密码在构建镜像时已经随机生成，保存在容器的`/home/user/.vnc/passwd`文件中。你可以通过运行`docker exec`命令查看这个文件来获取密码。

```bash
docker exec -it <container_id> cat /home/user/.vnc/passwd
```

其中，`<container_id>`是你正在运行的Docker容器的ID，你可以通过运行`docker ps`命令来获取。

此外，你也可以在运行Docker容器时通过环境变量`VNC_GEOMETRY`来设置VNC的分辨率，例如：

```bash
docker run -d -p 8900:8900 -e VNC_GEOMETRY=1920x1080 vnc-novnc:latest
```

这将设置VNC的分辨率为1920x1080。
