Check on TODO's with TODO Tree extension

To create the remote state management bucket, kms key, dynamodb locking table, and replica, run:

```bash
chmod +x ./start.sh
./start.sh
```

## If you are going to run

```bash
terraform destroy
```

make sure to update the dynamodb to have deletion protection set to false.
