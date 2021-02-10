#!/bin/bash

hexo clean
cnpm install --save hexo-deployer-git
hexo d
