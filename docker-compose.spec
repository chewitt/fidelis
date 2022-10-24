%global _prefix /usr/local

Name:    docker-compose
Version: @@VERSION@@
Release: 1
Summary: Define and run multi-container applications with Docker https://docs.docker.com/compose/
Group:   Development Tools
License: ASL 2.0
Source0: https://github.com/docker/compose/releases/download/v%{version}/docker-compose-linux-x86_64

%description
Docker Compose is a tool for running multi-container applications on Docker defined using
the Compose file format. A Compose file is used to define how the one or more containers
that make up your application are configured. Once you have a Compose file, you can create
and start your application with a single command

%install
mkdir -p %{buildroot}/%{_bindir}
%{__install} -m 755 %{SOURCE0} %{buildroot}%{_bindir}/%{name}

%files
%{_bindir}/%{name}
