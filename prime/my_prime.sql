
--
-- setup / reset databases
--

use `my`;

DELETE FROM `accounts`;
LOCK TABLES `accounts` WRITE;
/*!40000 ALTER TABLE `accounts` DISABLE KEYS */;
INSERT INTO `accounts` (id,name,balance,balance_limit,max_call_rate,max_users,max_duration,created_at,updated_at,owner_id,plan_code) VALUES (1,'Primary Account','0.00','0.00','0.00',100,240,NOW(),NOW(),NULL,'free');
/*!40000 ALTER TABLE `accounts` ENABLE KEYS */;
INSERT INTO `accounts` (id,name,balance,balance_limit,max_call_rate,max_users,max_duration,created_at,updated_at,owner_id,plan_code) VALUES (2,'Default\'s Primary Account','0.00','0.00','0.00',100,240,NOW(),NOW(),2,'free');
ALTER TABLE `accounts` AUTO_INCREMENT=10;
UNLOCK TABLES;

-- depreciate
DELETE FROM `billing_records`; ALTER TABLE `billing_records` AUTO_INCREMENT=10;

DELETE FROM `callees`; ALTER TABLE `callees` AUTO_INCREMENT=10;
DELETE FROM `colmodels`; ALTER TABLE `colmodels` AUTO_INCREMENT=10;

DELETE FROM `conferences`;
LOCK TABLES `conferences` WRITE;
/*!40000 ALTER TABLE `conferences` DISABLE KEYS */;
ALTER TABLE `conferences` ALTER `skin_id` SET DEFAULT 1;
INSERT INTO `conferences` (id,name,created_at,updated_at,owner_id,account_id,schedule,uri,skin_id,introduction) VALUES (1,'Master Conference Template',NOW(),NOW(),NULL,NULL,NULL,NULL,1,NULL);
INSERT INTO `conferences` (id,name,created_at,updated_at,owner_id,account_id,schedule,uri,skin_id,introduction) VALUES (2,'Demo',NOW(),NOW(),2,2,'s','demo',NULL,'Demo Conference');
/*!40000 ALTER TABLE `conferences` ENABLE KEYS */;
ALTER TABLE `conferences` AUTO_INCREMENT=10;
UNLOCK TABLES;

-- depreciate
DELETE FROM `countries`; ALTER TABLE `countries` AUTO_INCREMENT=10;

DELETE FROM `tokens`; ALTER TABLE `tokens` AUTO_INCREMENT=10;
DELETE FROM `emails`; ALTER TABLE `emails` AUTO_INCREMENT=10;

DELETE FROM `invitations`; ALTER TABLE `invitations` AUTO_INCREMENT=10;
INSERT INTO `invitations` (id,pin,role,created_at,updated_at,conference_id,user_id,dialin) VALUES (1,'888888','Host',NOW(),NOW(),2,2,NULL);

DELETE FROM `media_files`; ALTER TABLE `media_files` AUTO_INCREMENT=10;
DELETE FROM `phones`; ALTER TABLE `phones` AUTO_INCREMENT=10;

-- skip pin -- done externally based on initial prime or reset
-- DELETE FROM `pins`; ALTER TABLE `pins` AUTO_INCREMENT=10;

-- dont touch schema_migrations
-- DELETE FROM `schema_migrations`;
-- LOCK TABLES `schema_migrations` WRITE;
-- INSERT INTO `schema_migrations` VALUES ('20110109211852');
-- UNLOCK TABLES;

DELETE FROM `skins`;
ALTER TABLE `skins` AUTO_INCREMENT=10;
LOCK TABLES `skins` WRITE;
INSERT INTO `skins` (id,body,created_at,updated_at,name,immutable,preview_url) VALUES (1,NULL,NOW(),NOW(),'Classic (default)',0,'/cdn/v1/c/img/classic_preview.png');
ALTER TABLE `skins` AUTO_INCREMENT=10;
UNLOCK TABLES;

-- DELETE FROM ``; ALTER TABLE `` AUTO_INCREMENT=10;
-- DELETE FROM ``; ALTER TABLE `` AUTO_INCREMENT=10;
-- DELETE FROM ``; ALTER TABLE `` AUTO_INCREMENT=10;

DELETE FROM `users`;
LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` (id,crypted_password,salt,name,email_address,administrator,created_at,updated_at,state,last_name,timezone) VALUES (2,'3713602b0042c26ffa78ec392358c54d52274756','8ef1712c9e05d6427924f012f018b6d16c09e539','Default','default@bademail.bad',0,NOW(),NOW(),'active','Install','Pacific Time (US & Canada)');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
ALTER TABLE `users` AUTO_INCREMENT=10;
UNLOCK TABLES;

