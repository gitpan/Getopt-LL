#!/bin/bash
find . -type f \( ! -name 'Changes' \) -exec perl -pi -e's/0\.0\.4/0.0.5/g' {} \;
