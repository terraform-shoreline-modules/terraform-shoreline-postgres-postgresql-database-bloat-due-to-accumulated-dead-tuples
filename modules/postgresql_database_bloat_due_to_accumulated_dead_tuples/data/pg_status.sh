sudo systemctl status postgresql | grep "Active: active (running)" > /dev/null

if [ $? -ne 0 ]; then
  echo "PostgreSQL is not running"
  exit 1
fi