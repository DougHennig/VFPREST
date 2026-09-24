# VFPREST

[![ChangeLog](https://img.shields.io/github/last-commit/DougHennig/VFPREST?path=ChangeLog.md&label=Latest%20Release)](ChangeLog.md)

According to Wikipedia,

> "REST (Representational State Transfer) is a software architectural style that was created to describe the design and guide the development of the architecture for the World Wide Web. ... The REST architectural style emphasizes uniform interfaces, independent deployment of components, the scalability of interactions between them, and creating a layered architecture to promote caching to reduce user-perceived latency, enforce security, and encapsulate legacy systems."

REST services, sometimes called RESTful web services, are a lightweight and scalable way to design networked applications that communicate over HTTP using standard methods like GET, POST, PUT, and DELETE.

There are lots of ways to make a REST API call in VFP applications:

* WinHttp.WinHttpRequest, which is built into Windows.

* West Wind Technologies' wwHTTP class, part of West Wind Internet & Client Tools and West Wind Web Connection (<a href="https://west-wind.com" target="_blank">https://west-wind.com</a>).

* Chilkat Software’s Chilkat utility (https://www.chilkatsoft.com). Bill Anderson has a wrapper class (<a href="https://github.com/billand88/ChilkatVFP" target="_blank">https://github.com/billand88/ChilkatVFP</a>) that makes using Chilkat from VFP easier.

* CURL, a command-line utility that comes with Windows for transferring data to or from a server via a URL.

VFPREST provides a set of classes that make it much easier to call REST APIs. See the [documentation](Documentation/Documentation.md) for details on how to use this project.

## Installing

You can either download the files from here or use [FoxGet](https://github.com/doughennig/foxget) to install it for a project.

## Helping with this project

See [How to contribute to VFPREST](.github/CONTRIBUTING.md) for details on how to help with this project.

## Releases

See the [change log](ChangeLog.md) for release information.