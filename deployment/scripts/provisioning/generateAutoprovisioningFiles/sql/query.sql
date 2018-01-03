SELECT * INTO OUTFILE '/opt/SIU_MANAGER/scripts/generateAutoprovCDRs/tmp/cdr-result.csv' from DEG_AUTOPROVISIONING where provisioned ='no';
update DEG_AUTOPROVISIONING set provisioned = 'yes'; 

#insert into DEG_AUTOPROVISIONING(username,Node_id,Command,Unique_id,Realm,Details,Request_id,Result_code,Provisioned)values('310151000000001','core1','getEntitlement','49015420323751','eps.mnc015.mcc234.3gppnetwork.org','VoWiFi','1','6106','no');
