
--
-- setup / reset databases
--

USE `netops`;

DELETE FROM `calls`;
ALTER TABLE `calls` AUTO_INCREMENT=1;

DELETE FROM `colmodels`;
ALTER TABLE `colmodels` AUTO_INCREMENT=1;

DELETE FROM `conferences`;
ALTER TABLE `conferences` AUTO_INCREMENT=1;

DELETE FROM `emails`;
ALTER TABLE `emails` AUTO_INCREMENT=1;

DELETE FROM `interconnects`;
ALTER TABLE `interconnects` AUTO_INCREMENT=1;
-- data is populated every restart with netops_db_syscfg

-- depreciate
DELETE FROM `job_triggers`;
ALTER TABLE `job_triggers` AUTO_INCREMENT=1;

DELETE FROM `jobs`;
ALTER TABLE `jobs` AUTO_INCREMENT=1;

DELETE FROM `logs`;
ALTER TABLE `logs` AUTO_INCREMENT=1;

DELETE FROM `people`;
ALTER TABLE `people` AUTO_INCREMENT=1;

-- depreciate
DELETE FROM `pins`;
ALTER TABLE `pins` AUTO_INCREMENT=1;

-- dont touch schema migrations
-- DELETE FROM `schema_migrations`;
-- LOCK TABLES `schema_migrations` WRITE;
-- INSERT INTO `schema_migrations` VALUES ('20101127081456');
-- UNLOCK TABLES;

DELETE FROM `script_formats`;
ALTER TABLE `script_formats` AUTO_INCREMENT=1;

DELETE FROM `scripts`;
ALTER TABLE `scripts` AUTO_INCREMENT=38;
LOCK TABLES `scripts` WRITE;
/*!40000 ALTER TABLE `scripts` DISABLE KEYS */;
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (1,'freeswitch_assign.pl','Assign pending conferences to active freeswitch conference instances',NOW(),NOW(),'running=always');
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (2,'mailer.pl','Expand email from templates and send \'em',NOW(),NOW(),'running=always');
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (4,'scheduler.pl','This is the main \'cron\' scheduler',NOW(),NOW(),'**scheduler**');
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (5,'freeswitch_deploy.pl','Push freeswitch records out to assigned server',NOW(),NOW(),'running=always');
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (9,'fs_conference_monitor.pl','Detect and relay FreeSwitch conference status, primarily conference starting and terminating',NOW(),NOW(),'foreach_freeswitch=always');
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (13,'provisioning_sync.pl','Synchronize conference data between netops and provisioning using DB',NOW(),NOW(),'foreach_provisioning=always');
-- INSERT INTO `scripts` VALUES (17,'WAVtoMP3.py','2011-02-13 13:37:32',1,NULL,'2011-02-13 13:40:35','2011-02-19 00:22:52',NULL,NULL);
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (18,'tokens.pl','tokens',NOW(),NOW(),'foreach_provisioning=always');
-- INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (21,'webhooks.pl','Process incoming webhook requests',NOW(),NOW(),'running=always');
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (23,'conference_close.pl','Remove or delete conference artifacts from a server and otherwise close out',NOW(),NOW(),'running=always');
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (24,'save_recording.pl','Program to migrate media from a FS server once conference has completed',NOW(),NOW(),'running=manual');
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (26,'make_slideshows.pl','Create slideshows from other file formats on provisioning systems',NOW(),NOW(),'foreach_provisioning=always');
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (27,'binlog.pl','Replicate from binlogs into message streams',NOW(),NOW(),'foreach_provisioning=always');
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (28,'calls.pl','Update call information - info and accounting',NOW(),NOW(),'foreach_provisioning=always');
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (29,'freeswitch_undeploy.pl','Undeploy a conference from a server',NOW(),NOW(),'running=always');
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (30,'prep_conference.pl','Create estream queue on server', NOW(), NOW(), 'running=always');
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (31,'clean.pl','Clean',NOW(),NOW(),'foreach_provisioning=22 23 * * *');
-- INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (34,'recurly.pl','Synchronize account/billing data between provisioning and recurly',NOW(),NOW(),'foreach_provisioning=always');
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (35,'media_move.pl','Program to migrate media from a FS server once conference has completed',NOW(),NOW(),'running=always');
-- INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (36,'cheddargetter.rb','Synchronize account/billing data between provisioning and cheddargetter',NOW(),NOW(),'disabled____foreach_provisioning=always');
/*!40000 ALTER TABLE `scripts` ENABLE KEYS */;
INSERT INTO `scripts` (id,name,description,created_at,updated_at,startup) VALUES (37,'invitations_sync.pl','Synchronize invitations with people',NOW(),NOW(),'foreach_provisioning=always');
UNLOCK TABLES;

-- depreciate
DELETE FROM `server_services`;
ALTER TABLE `server_services` AUTO_INCREMENT=1;

-- depreciate
DELETE FROM `service_metrics`;
ALTER TABLE `service_metrics` AUTO_INCREMENT=1;

-- depreciate
DELETE FROM `services`;
ALTER TABLE `services` AUTO_INCREMENT=1;

DELETE FROM `systems`;
ALTER TABLE `systems` AUTO_INCREMENT=1;
-- data is populated every restart with netops_db_syscfg

-- users for netops admin UI
DELETE FROM `users`;
ALTER TABLE `users` AUTO_INCREMENT=1;

DELETE FROM `webhooks`;
ALTER TABLE `webhooks` AUTO_INCREMENT=1;

