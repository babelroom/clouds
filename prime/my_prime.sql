
--
-- setup / reset databases
--

use `my`;

DELETE FROM `accounts`;
LOCK TABLES `accounts` WRITE;
/*!40000 ALTER TABLE `accounts` DISABLE KEYS */;
INSERT INTO `accounts` (id,name,balance,balance_limit,max_call_rate,max_users,max_duration,created_at,updated_at,owner_id,plan_code) VALUES (1,'Primary Account','0.00','0.00','0.00',100,240,NOW(),NOW(),NULL,'free');
/*!40000 ALTER TABLE `accounts` ENABLE KEYS */;
INSERT INTO `accounts` (id,name,balance,balance_limit,max_call_rate,max_users,max_duration,created_at,updated_at,owner_id,plan_code) VALUES (2,'Dr\'s Primary Account','0.00','0.00','0.00',100,240,NOW(),NOW(),2,'free');
INSERT INTO `accounts` (id,name,balance,balance_limit,max_call_rate,max_users,max_duration,created_at,updated_at,owner_id,plan_code) VALUES (3,'Default\'s Primary Account','0.00','0.00','0.00',100,240,NOW(),NOW(),3,'free');
ALTER TABLE `accounts` AUTO_INCREMENT=4;
UNLOCK TABLES;

-- depreciate
DELETE FROM `billing_records`; ALTER TABLE `billing_records` AUTO_INCREMENT=1;

DELETE FROM `callees`; ALTER TABLE `callees` AUTO_INCREMENT=1;
DELETE FROM `colmodels`; ALTER TABLE `colmodels` AUTO_INCREMENT=1;

DELETE FROM `conferences`;
LOCK TABLES `conferences` WRITE;
/*!40000 ALTER TABLE `conferences` DISABLE KEYS */;
INSERT INTO `conferences` (id,name,created_at,updated_at,owner_id,schedule,uri,skin_id,introduction) VALUES (1,'Master Conference Template',NOW(),NOW(),NULL,NULL,NULL,1,NULL);
INSERT INTO `conferences` (id,name,created_at,updated_at,owner_id,schedule,uri,skin_id,introduction) VALUES (2,'Demo',NOW(),NOW(),2,'s','demo',NULL,'Demo Conference');
/*!40000 ALTER TABLE `conferences` ENABLE KEYS */;
ALTER TABLE `conferences` AUTO_INCREMENT=3;
UNLOCK TABLES;

-- depreciate
DELETE FROM `countries`; ALTER TABLE `countries` AUTO_INCREMENT=1;

DELETE FROM `tokens`; ALTER TABLE `tokens` AUTO_INCREMENT=1;
DELETE FROM `emails`; ALTER TABLE `emails` AUTO_INCREMENT=1;

DELETE FROM `invitations`; ALTER TABLE `invitations` AUTO_INCREMENT=1;
INSERT INTO `invitations` (id,pin,role,created_at,updated_at,conference_id,user_id,dialin) VALUES (1,'888888','Host',NOW(),NOW(),2,2,NULL);

DELETE FROM `media_files`; ALTER TABLE `media_files` AUTO_INCREMENT=1;
DELETE FROM `phones`; ALTER TABLE `phones` AUTO_INCREMENT=1;

-- skip pin -- done externally based on initial prime or reset
-- DELETE FROM `pins`; ALTER TABLE `pins` AUTO_INCREMENT=1;

--- don't touch schema_migrations
--- DELETE FROM `schema_migrations`;
--- LOCK TABLES `schema_migrations` WRITE;
/*!40000 ALTER TABLE `schema_migrations` DISABLE KEYS */;
--- INSERT INTO `schema_migrations` VALUES ('20110109211852');
/*!40000 ALTER TABLE `schema_migrations` ENABLE KEYS */;
--- UNLOCK TABLES;

DELETE FROM `skins`;
ALTER TABLE `skins` AUTO_INCREMENT=1;
LOCK TABLES `skins` WRITE;
INSERT INTO `skins` (id,body,created_at,updated_at,name,immutable,preview_url) VALUES (1,NULL,NOW(),NOW(),'Classic (default)',0,'/v1/c/img/classic_preview.png');
ALTER TABLE `skins` AUTO_INCREMENT=2;
UNLOCK TABLES;

-- DELETE FROM ``; ALTER TABLE `` AUTO_INCREMENT=1;
-- DELETE FROM ``; ALTER TABLE `` AUTO_INCREMENT=1;
-- DELETE FROM ``; ALTER TABLE `` AUTO_INCREMENT=1;

DELETE FROM `users`;
LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` (id,crypted_password,salt,name,email_address,administrator,created_at,updated_at,state,last_name,timezone) VALUES (2,'6f8d2a4dd125f747e717b651e1dafa5a46ac2ece','8ef1712c9e05d6427924f012f018b6d16c09e539','Dr','demo@babelroom.com',0,NOW(),NOW(),'active','Demo','Pacific Time (US & Canada)');
INSERT INTO `users` (id,crypted_password,salt,name,email_address,administrator,created_at,updated_at,state,last_name,timezone) VALUES (3,'6f8d2a4dd125f747e717b651e1dafa5a46ac2ece','8ef1712c9e05d6427924f012f018b6d16c09e539','Default','john@babelroom.com',0,NOW(),NOW(),'active','Install','Pacific Time (US & Canada)');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
ALTER TABLE `users` AUTO_INCREMENT=4;
UNLOCK TABLES;

