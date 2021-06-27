import csv
import yaml
import os

environments = ["qa","prod"]



#For each environment
for environment in environments:
   
    #Loading IP map configuration (default + environment specifics)
    with open(r'ip_mapping.yaml') as ipmap_file:

        ip_map_full = yaml.load(ipmap_file, Loader=yaml.FullLoader)
        ip_map = ip_map_full["default"]
        ip_map.update(ip_map_full[environment])
    ipmap_file.close()

         
    #Creating a new csv file document with headers. 
    filename = "sg/" + environment + "/" + "sample-sg.csv"
        
    os.remove(filename)


    with open(filename,'a',newline='') as policy_file:
            writer = csv.writer(policy_file)
            writer.writerow(["rule_id","source_name","source_cidr","destination_name","destination_cidr","protocol","From_Port","To_Port","Description"])
             
        
          #Read the csv file. 
          #For each securitygrouprules.csv create a new entry to the file with CIDRs
            with open('securitygrouprules.csv',mode='r') as rules_file:
                 csv_reader = csv.DictReader(rules_file)
                 for row in csv_reader:
                     if row['Status'] == "ACTIVE":
                         writer.writerow([row["rule_id"],row["Source"],ip_map[row["Source"]],row["Destination"],row["Protocol"],row["From_Port"],row["To_Port"],row["Description"]]) 
            rules_file.close()
    policy_file.close()

