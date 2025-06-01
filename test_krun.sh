#!/bin/bash
# Test script for krun multi-language support

echo "=== Testing Krun Multi-Language Support ==="
echo ""

echo "1. Testing Python version:"
cd bin && python3 krun version
echo ""

echo "2. Testing Shell version:"
./krun.sh version
echo ""

echo "3. Testing Go version:"
cd krun-go && go run krun.go version
cd ..
echo ""

echo "4. Testing Ruby version:"
ruby krun.rb version
echo ""

echo "5. Testing Perl version:"
perl krun.pl version
echo ""

echo "=== Testing language support ==="
echo "Python version - languages:"
python3 krun languages
echo ""

echo "Shell version - status:"
./krun.sh status
echo ""

echo "=== All tests completed ==="
