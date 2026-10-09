id,type,name,cidr_block,protocol,from_port,to_port,description
0,egress,security-group-1,${node_group_cidr},tcp,0,0,egress for pods for nginx
1,egress,security-group-1,${node_group_cidr},tcp,27017,27017,docdb - 27017
2,egress,security-group-1,"10.2.20.0/24,10.2.21.0/24",tcp,6379,6379,docdb - 6379
3,egress,security-group-1,"10.2.20.0/24,10.2.21.0/24",tcp,8089,8089,docdb - 8089
