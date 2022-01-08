#!/bin/bash

function dir_exists() {
	[ -n "$(ls -A $1)" ]
}
