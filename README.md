# Docker dumphfdl

![Banner](https://github.com/sdr-enthusiasts/docker-acarshub/blob/16ab3757986deb7c93c08f5c7e3752f54a19629c/Logo-Sources/ACARS%20Hub.png "banner")
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/fredclausen/docker-acarshub/Deploy%20to%20Docker%20Hub)](https://github.com/sdr-enthusiasts/docker-acarshub/actions?query=workflow%3A%22Deploy+to+Docker+Hub%22)
[![Docker Pulls](https://img.shields.io/docker/pulls/fredclausen/acarshub.svg)](https://hub.docker.com/r/fredclausen/acarshub)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/fredclausen/acarshub/latest)](https://hub.docker.com/r/fredclausen/acarshub)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container for running [dumphfdl](https://github.com/szpajder/dumphfdl) and forwarding the received JSON messages to another system or docker container. Best used alongside [ACARS Hub](https://github.com/fredclausen/acarshub).

Builds and runs on `amd64`, `arm64`, `arm/v7`, `arm/v6` and `386` architectures.

***WORK IN PROGRESS. `acars_router` and `ACARS Hub` support is a WIP***

## Note for Users running 32-bit Debian Buster-based OSes on ARM

Please see: [Buster-Docker-Fixes](https://github.com/fredclausen/Buster-Docker-Fixes)!

## Required hardware

A computer host on a suitable architecture and one USB RTL-SDR dongle connected to an antenna.

## ACARS Hub integration

The configuration below will enable integration with `acars_router`, which should be configured to forward messages to `acarshub`.

## Up and running

```yaml
version: '2.0'

services:
  dumphfdl:
    image: ghcr.io/sdr-enthusiasts/docker-dumphfdl:latest
    tty: true
    container_name: dumphfdl
    restart: always
    device_cgroup_rules:
      - "c 189:* rwm"
    environment:
      - TZ=${FEEDER_TZ}
      - SOAPYSDRDRIVER=driver=airspyhf,serial=0x3b52aa80389e25ad
      - GAIN_TYPE=--gain
      - SOAPYSAMPLERATE=912000
      - GAIN=40
      - FEED_ID=CS-KABQ-HFDL
      - ZMQ_MODE=server
      - ZMQ_ENDPOINT=tcp://0.0.0.0:45555
      - SERVER=
    tmpfs:
      - /run:exec,size=64M
      - /var/log
      - /tmp
    volumes:
      - /dev:/dev:ro

```

## Supported SDRs

Any device that can be run via SoapySDR with the following drivers should, in theory, work:

* `airspyhf`
* `airspy`

Keep in mind not every SDR is usable with HF decoding. If you have an SDR that is supported in Soapy, and not listed above, please contact me on discord and I'll see about adding support.

## Configuration options

| Variable | Description | Required | Default |
|----------|-------------|---------|--------|
| `TZ` | Your timezone | No | UTC |
| `SOAPYSDRDRIVER` | SoapySDR driver. Required! Should be in the format that you would use to pass in to soapysdr. See the compose example above. | Yes | `unset` |
| `GAIN_TYPE` | The type of gain to use. Can be `--gain` or `--gain-elements`. | Yes | `unset` |
| `GAIN` | The gain to use. If used with `GAIN_TYPE=--gain-elements` then this should be in the format your SDR expects. For Airspy style devices something like `IFGR=53,RFGR=2`. Otherwise, if used with `GAIN_TYPE=--gain` then it should be a single value representing a gain value your SDR supports. Example above in the compose section. | Yes | `unset` |
| `SOAPYSAMPLERATE` | The sample rate to use. The sample rate that your SDR would expect.  | Yes | `unset` |
| `FEED_ID` | The feed ID to use. This is the ID that will be used to identify your feed on the ACARS Hub and any site, such as [airframes](airframes.io) that you feed. | Yes | `unset` |
| `ZMQ_MODE` | The ZMQ mode to use. Can be `server` or `client`. | Yes | `unset` |
| `ZMQ_ENDPOINT` | The ZMQ endpoint to use. If `ZMQ_MODE=server` then this should be the endpoint that `acars_router` and other consumers will connect to. If `ZMQ_MODE=client` then this should be the endpoint that a ZMQ server is listening on and expects data from. | Yes | `unset` |
| `SERVER` | If you want this container to forward JSON data, via TCP, to a consumer then set this to the IP address of a consumer| No | `unset` |
| `SERVER_PORT` | If you want this container to forward JSON data, via TCP, to a consumer then set this to the port of a consumer | No | `unset` |
