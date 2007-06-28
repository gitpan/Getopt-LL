#!/bin/bash
find . -type f \( ! -name 'Changes' \) -exec perl -pi -e's/0\.0\.3/0.0.4/g' {} \;
