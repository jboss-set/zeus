#!/bin/bash

ip -6 route add table local local ff13::/16 dev lo metric 5