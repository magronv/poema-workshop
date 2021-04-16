#!/bin/bash

print_path() {
    echo $PATH | sed 's/:/\n/g'
}
