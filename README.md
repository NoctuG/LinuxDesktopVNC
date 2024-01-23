# LinuxDesktopVNC 使用指南

这个 Dockerfile 用于创建一个带有 VNC 和 noVNC 的 Docker 镜像，以便于在 Web 浏览器中远程访问虚拟桌面。以下是如何使用这个 Dockerfile 的步骤。

## 前提条件

确保你的系统已经安装了 Docker。如果没有，请参照[Docker 官方文档](https://docs.docker.com/get-docker/)进行安装。

## 构建 Docker 镜像

首先，你需要构建 Docker 镜像。将 Dockerfile 保存到本地，然后在 Dockerfile 所在的目录运行以下命令：

```bash
docker build -t vnc-novnc:latest .
```

这将创建一个名为 `vnc-novnc` 的 Docker 镜像，标签为 `latest`。

## 运行 Docker 容器

然后，你可以运行一个 Docker 容器，使用以下命令：

```bash
docker run -d -p 8900:8900 -p 2000:2000 vnc-novnc:latest
```

这将在后台运行一个 Docker 容器，并将容器的 8900 端口映射到主机的 8900 端口。

## 访问虚拟桌面

最后，你可以在 Web 浏览器中访问 `http://localhost:8900`，以远程访问虚拟桌面。

在 Dockerfile 中，我们已经设置了用户和 root 的密码为 "password"，你可以在启动容器时通过设置环境变量 `USER_PASSWORD` 和 `ROOT_PASSWORD` 来修改这些密码，例如：

```bash
docker run -d -p 8900:8900 -e USER_PASSWORD=your_password -e ROOT_PASSWORD=your_password vnc-novnc:latest
```

这将设置用户和 root 的密码为 "your_password"。

此外，你也可以在运行 Docker 容器时通过环境变量 `VNC_GEOMETRY` 来设置 VNC 的分辨率，不过在当前的 Dockerfile 和 setup.sh 中并没有这个选项，如果需要，你可以修改 setup.sh 脚本来支持这个功能。
