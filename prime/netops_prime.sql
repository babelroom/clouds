
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

-- depreciate
DELETE FROM `job_triggers`;
ALTER TABLE `job_triggers` AUTO_INCREMENT=1;

DELETE FROM `jobs`;
ALTER TABLE `jobs` AUTO_INCREMENT=1;

-- depreciate ??
DELETE FROM `interconnects`;
ALTER TABLE `interconnects` AUTO_INCREMENT=2;
LOCK TABLES `interconnects` WRITE;
/*!40000 ALTER TABLE `interconnects` DISABLE KEYS */;
INSERT INTO `interconnects` VALUES (1,'US +1 (415) 449 8899','','2012-01-17 08:21:19','2012-08-22 02:39:00','',NULL);
/*!40000 ALTER TABLE `interconnects` ENABLE KEYS */;
UNLOCK TABLES;

DELETE FROM `logs`;
ALTER TABLE `logs` AUTO_INCREMENT=1;

DELETE FROM `people`;
ALTER TABLE `people` AUTO_INCREMENT=1;

-- depreciate
DELETE FROM `pins`;
ALTER TABLE `pins` AUTO_INCREMENT=1;

DELETE FROM `schema_migrations`;
LOCK TABLES `schema_migrations` WRITE;
/*!40000 ALTER TABLE `schema_migrations` DISABLE KEYS */;
INSERT INTO `schema_migrations` VALUES ('20101127081456');
INSERT INTO `schema_migrations` VALUES ('20101201060813');
INSERT INTO `schema_migrations` VALUES ('20101201063606');
INSERT INTO `schema_migrations` VALUES ('20101218013204');
INSERT INTO `schema_migrations` VALUES ('20101218204021');
INSERT INTO `schema_migrations` VALUES ('20101218204116');
INSERT INTO `schema_migrations` VALUES ('20101218213656');
INSERT INTO `schema_migrations` VALUES ('20101220000817');
INSERT INTO `schema_migrations` VALUES ('20101220001546');
INSERT INTO `schema_migrations` VALUES ('20101220003355');
INSERT INTO `schema_migrations` VALUES ('20101220004204');
INSERT INTO `schema_migrations` VALUES ('20101220004313');
INSERT INTO `schema_migrations` VALUES ('20101220004452');
INSERT INTO `schema_migrations` VALUES ('20101220004509');
INSERT INTO `schema_migrations` VALUES ('20101220004601');
INSERT INTO `schema_migrations` VALUES ('20101220004642');
INSERT INTO `schema_migrations` VALUES ('20101220004652');
INSERT INTO `schema_migrations` VALUES ('20101220005031');
INSERT INTO `schema_migrations` VALUES ('20101220005400');
INSERT INTO `schema_migrations` VALUES ('20101220010752');
INSERT INTO `schema_migrations` VALUES ('20101220015324');
INSERT INTO `schema_migrations` VALUES ('20101220015358');
INSERT INTO `schema_migrations` VALUES ('20101220015435');
INSERT INTO `schema_migrations` VALUES ('20101220015509');
INSERT INTO `schema_migrations` VALUES ('20101220032149');
INSERT INTO `schema_migrations` VALUES ('20101220032204');
INSERT INTO `schema_migrations` VALUES ('20101220215112');
INSERT INTO `schema_migrations` VALUES ('20101220215556');
INSERT INTO `schema_migrations` VALUES ('20101220220006');
INSERT INTO `schema_migrations` VALUES ('20101220225105');
INSERT INTO `schema_migrations` VALUES ('20101221023153');
INSERT INTO `schema_migrations` VALUES ('20101221023324');
INSERT INTO `schema_migrations` VALUES ('20101221023541');
INSERT INTO `schema_migrations` VALUES ('20110119022433');
INSERT INTO `schema_migrations` VALUES ('20110119022732');
INSERT INTO `schema_migrations` VALUES ('20110119022741');
INSERT INTO `schema_migrations` VALUES ('20110119022832');
INSERT INTO `schema_migrations` VALUES ('20110119022925');
INSERT INTO `schema_migrations` VALUES ('20110119025903');
INSERT INTO `schema_migrations` VALUES ('20110119030508');
INSERT INTO `schema_migrations` VALUES ('20110119040105');
INSERT INTO `schema_migrations` VALUES ('20110119061422');
INSERT INTO `schema_migrations` VALUES ('20110119193106');
INSERT INTO `schema_migrations` VALUES ('20110119193146');
INSERT INTO `schema_migrations` VALUES ('20110119193715');
INSERT INTO `schema_migrations` VALUES ('20110119195302');
INSERT INTO `schema_migrations` VALUES ('20110119195317');
INSERT INTO `schema_migrations` VALUES ('20110120013849');
INSERT INTO `schema_migrations` VALUES ('20110120023942');
INSERT INTO `schema_migrations` VALUES ('20110120024002');
INSERT INTO `schema_migrations` VALUES ('20110120223211');
INSERT INTO `schema_migrations` VALUES ('20110120223325');
INSERT INTO `schema_migrations` VALUES ('20110120223526');
INSERT INTO `schema_migrations` VALUES ('20110120223553');
INSERT INTO `schema_migrations` VALUES ('20110121001300');
INSERT INTO `schema_migrations` VALUES ('20110123212126');
INSERT INTO `schema_migrations` VALUES ('20110123223212');
INSERT INTO `schema_migrations` VALUES ('20110123223314');
INSERT INTO `schema_migrations` VALUES ('20110123225813');
INSERT INTO `schema_migrations` VALUES ('20110123225841');
INSERT INTO `schema_migrations` VALUES ('20110124001648');
INSERT INTO `schema_migrations` VALUES ('20110124001721');
INSERT INTO `schema_migrations` VALUES ('20110124055743');
INSERT INTO `schema_migrations` VALUES ('20110124221122');
INSERT INTO `schema_migrations` VALUES ('20110124221236');
INSERT INTO `schema_migrations` VALUES ('20110127013614');
INSERT INTO `schema_migrations` VALUES ('20110127013814');
INSERT INTO `schema_migrations` VALUES ('20110127072459');
INSERT INTO `schema_migrations` VALUES ('20110128023444');
INSERT INTO `schema_migrations` VALUES ('20110128030439');
INSERT INTO `schema_migrations` VALUES ('20110128030514');
INSERT INTO `schema_migrations` VALUES ('20110128060736');
INSERT INTO `schema_migrations` VALUES ('20110128061045');
INSERT INTO `schema_migrations` VALUES ('20110128061149');
INSERT INTO `schema_migrations` VALUES ('20110128061201');
INSERT INTO `schema_migrations` VALUES ('20110128061230');
INSERT INTO `schema_migrations` VALUES ('20110128061251');
INSERT INTO `schema_migrations` VALUES ('20110128061319');
INSERT INTO `schema_migrations` VALUES ('20110216000145');
INSERT INTO `schema_migrations` VALUES ('20110216001746');
INSERT INTO `schema_migrations` VALUES ('20110216001847');
INSERT INTO `schema_migrations` VALUES ('20110216002056');
INSERT INTO `schema_migrations` VALUES ('20110217000256');
INSERT INTO `schema_migrations` VALUES ('20110217000257');
INSERT INTO `schema_migrations` VALUES ('20110217211824');
INSERT INTO `schema_migrations` VALUES ('20110219030256');
INSERT INTO `schema_migrations` VALUES ('20110220045644');
INSERT INTO `schema_migrations` VALUES ('20110220054526');
INSERT INTO `schema_migrations` VALUES ('20110303220657');
INSERT INTO `schema_migrations` VALUES ('20110303230826');
INSERT INTO `schema_migrations` VALUES ('20110304070028');
INSERT INTO `schema_migrations` VALUES ('20110512173235');
INSERT INTO `schema_migrations` VALUES ('20110512222919');
INSERT INTO `schema_migrations` VALUES ('20110601054422');
INSERT INTO `schema_migrations` VALUES ('20110601061152');
INSERT INTO `schema_migrations` VALUES ('20110601061459');
INSERT INTO `schema_migrations` VALUES ('20110617224428');
INSERT INTO `schema_migrations` VALUES ('20110821174153');
INSERT INTO `schema_migrations` VALUES ('20110821191846');
INSERT INTO `schema_migrations` VALUES ('20110827183215');
/*!40000 ALTER TABLE `schema_migrations` ENABLE KEYS */;
UNLOCK TABLES;

DELETE FROM `script_formats`;
ALTER TABLE `script_formats` AUTO_INCREMENT=1;

DELETE FROM `scripts`;
ALTER TABLE `scripts` AUTO_INCREMENT=38;
LOCK TABLES `scripts` WRITE;
/*!40000 ALTER TABLE `scripts` DISABLE KEYS */;
INSERT INTO `scripts` VALUES (1,'freeswitch_assign.pl','2011-11-25 18:31:30',NULL,'Assign pending conferences to active freeswitch conference instances','2011-02-05 13:45:10','2012-04-19 15:43:56','running=always',NULL);
INSERT INTO `scripts` VALUES (2,'mailer.pl','2011-11-25 18:31:30',NULL,'Expand email from templates and send \'em',NOW(),NOW(),'running=always',NULL);
-- INSERT INTO `scripts` VALUES (3,'examples/hello.pl','2011-11-25 18:31:30',NULL,'This is a description. I like descriptions.','2011-02-05 13:45:10','2012-04-19 15:43:56','startup flags',NULL);
INSERT INTO `scripts` VALUES (4,'scheduler.pl','2011-11-25 18:31:30',NULL,'This is the main \'cron\' scheduler','2011-02-05 13:45:10','2012-04-19 15:43:56','**scheduler**',NULL);
INSERT INTO `scripts` VALUES (5,'freeswitch_deploy.pl','2011-11-25 18:31:30',NULL,'Push freeswitch records out to assigned server','2011-02-05 13:45:10','2012-04-19 15:43:56','running=always',NULL);
-- INSERT INTO `scripts` VALUES (6,'CSJobs.pm','2011-11-25 18:31:30',NULL,NULL,'2011-02-05 13:45:10','2012-04-19 15:43:57',NULL,NULL);
-- INSERT INTO `scripts` VALUES (7,'EStream.pm','2011-11-25 18:31:30',NULL,NULL,'2011-02-05 13:45:10','2012-04-19 15:43:57',NULL,NULL);
-- INSERT INTO `scripts` VALUES (8,'CSDB.pm','2011-02-18 17:41:28',1,NULL,'2011-02-05 13:45:10','2012-04-19 15:43:57',NULL,NULL);
INSERT INTO `scripts` VALUES (9,'fs_conference_monitor.pl','2011-11-25 18:31:30',NULL,'Detect and relay FreeSwitch conference status, primarily conference starting and terminating','2011-02-05 13:45:10','2012-04-19 15:43:57','foreach_freeswitch=always',NULL);
-- INSERT INTO `scripts` VALUES (10,'import.pl','2011-01-29 07:32:53',1,NULL,'2011-02-05 13:45:10','2011-02-19 00:22:52',NULL,NULL);
-- INSERT INTO `scripts` VALUES (11,'init.pl','2012-04-19 08:43:45',NULL,NULL,'2011-02-05 13:45:10','2012-04-19 15:43:57',NULL,NULL);
-- INSERT INTO `scripts` VALUES (12,'my.sql','2011-01-29 07:32:53',1,NULL,'2011-02-05 13:45:10','2011-02-19 00:22:52',NULL,NULL);
INSERT INTO `scripts` VALUES (13,'provisioning_sync.pl','2011-11-25 18:31:30',NULL,'Synchronize conference data between netops and provisioning using DB','2011-02-05 13:45:10','2012-04-19 15:43:57','foreach_provisioning=always',NULL);
-- INSERT INTO `scripts` VALUES (14,'users_sync.pl','2011-11-25 18:31:30',NULL,'Synchronize user data between netops and provisionging using DB','2011-02-05 13:45:10','2012-04-19 15:43:57','foreach_provisioning=always',NULL);
-- INSERT INTO `scripts` VALUES (15,'sync.pl','2011-11-25 18:31:30',NULL,'Internal do not use','2011-02-05 13:45:10','2012-04-19 15:43:57','hidden',NULL);
-- INSERT INTO `scripts` VALUES (16,'examples/hello.py','2011-11-25 18:31:30',NULL,'I am a python program','2011-02-05 13:45:10','2012-04-19 15:43:57','startup flags',NULL);
-- INSERT INTO `scripts` VALUES (17,'WAVtoMP3.py','2011-02-13 13:37:32',1,NULL,'2011-02-13 13:40:35','2011-02-19 00:22:52',NULL,NULL);
INSERT INTO `scripts` VALUES (18,'tokens.pl','2011-11-25 18:31:30',NULL,'tokens',NOW(),NOW(),'foreach_provisioning=always',NULL);
-- INSERT INTO `scripts` VALUES (19,'CSConfig.pm','2011-11-25 18:31:30',NULL,NULL,'2012-04-19 15:43:56','2012-04-19 15:43:56',NULL,NULL);
-- INSERT INTO `scripts` VALUES (20,'CSRate.pm','2011-11-25 18:31:30',NULL,NULL,'2012-04-19 15:43:56','2012-04-19 15:43:56',NULL,NULL);
INSERT INTO `scripts` VALUES (21,'webhooks.pl','2011-11-25 18:31:30',NULL,'Process incoming webhook requests','2012-04-19 15:43:56','2012-04-19 15:43:56','running=always',NULL);
-- INSERT INTO `scripts` VALUES (22,'Emails.pm','2011-11-25 18:31:30',NULL,NULL,'2012-04-19 15:43:56','2012-04-19 15:43:56',NULL,NULL);
INSERT INTO `scripts` VALUES (23,'conference_close.pl','2011-11-25 18:31:30',NULL,'Remove or delete conference artifacts from a server and otherwise close out','2012-04-19 15:43:56','2012-04-19 15:43:56','running=always',NULL);
INSERT INTO `scripts` VALUES (24,'save_recording.pl','2011-11-25 18:31:30',NULL,'Program to migrate media from a FS server once conference has completed','2012-04-19 15:43:56','2012-04-19 15:43:56','running=manual',NULL);
-- INSERT INTO `scripts` VALUES (25,'rd_harvest.pl','2011-11-25 18:31:30',NULL,'Harvest RD phone calls','2012-04-19 15:43:56','2012-04-19 15:43:56','foreach_rd=always',NULL);
INSERT INTO `scripts` VALUES (26,'make_slideshows.pl','2011-11-25 18:31:30',NULL,'Create slideshows from other file formats on provisioning systems','2012-04-19 15:43:56','2012-04-19 15:43:56','foreach_provisioning=always',NULL);
INSERT INTO `scripts` VALUES (27,'binlog.pl','2011-11-25 18:31:30',NULL,'Replicate from binlogs into message streams','2012-04-19 15:43:56','2012-04-19 15:43:56','foreach_provisioning=always',NULL);
INSERT INTO `scripts` VALUES (28,'calls.pl','2011-11-25 18:31:30',NULL,'Update call information - info and accounting','2012-04-19 15:43:56','2012-04-19 15:43:56','foreach_provisioning=always',NULL);
INSERT INTO `scripts` VALUES (29,'freeswitch_undeploy.pl','2011-11-25 18:31:30',NULL,'Undeploy a conference from a server','2012-04-19 15:43:56','2012-04-19 15:43:56','running=always',NULL);
INSERT INTO `scripts` VALUES (30,'prep_conference.pl','2011-11-25 18:31:30',NULL,'Create estream queue on server','2012-04-19 15:43:56','2012-04-19 15:43:56','running=always',NULL);
INSERT INTO `scripts` VALUES (31,'clean.pl','2011-11-25 18:31:30',NULL,'Clean','2012-04-19 15:43:56','2012-04-19 15:43:56','foreach_provisioning=22 23 * * *',NULL);
-- INSERT INTO `scripts` VALUES (32,'rd_call.pl','2011-11-25 18:31:30',NULL,'RD get numbers and call them','2012-04-19 15:43:56','2012-04-19 15:43:56','foreach_rd=always',NULL);
-- INSERT INTO `scripts` VALUES (33,'CSFS.pm','2011-11-25 18:31:30',NULL,NULL,'2012-04-19 15:43:56','2012-04-19 15:43:56',NULL,NULL);
INSERT INTO `scripts` VALUES (34,'recurly.pl','2011-11-25 18:31:30',NULL,'Synchronize account/billing data between provisioning and recurly',NOW(),NOW(),'foreach_provisioning=always',NULL);
INSERT INTO `scripts` VALUES (35,'media_move.pl','2011-11-25 18:31:30',NULL,'Program to migrate media from a FS server once conference has completed','2012-04-19 15:43:56','2012-04-19 15:43:56','running=always',NULL);
-- INSERT INTO `scripts` VALUES (36,'cheddargetter.rb','2011-11-25 18:31:30',NULL,'Synchronize account/billing data between provisioning and cheddargetter','2012-04-19 15:43:56','2012-04-19 15:43:56','disabled____foreach_provisioning=always',NULL);
/*!40000 ALTER TABLE `scripts` ENABLE KEYS */;
INSERT INTO `scripts` VALUES (37,'invitations_sync.pl','2012-11-25 18:31:30',NULL,'Synchronize invitations with people','2011-02-05 13:45:10','2012-04-19 15:43:57','foreach_provisioning=always',NULL);
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
ALTER TABLE `systems` AUTO_INCREMENT=15;
LOCK TABLES `systems` WRITE;
/*!40000 ALTER TABLE `systems` DISABLE KEYS */;
INSERT INTO `systems` VALUES (1,'Provisional provisioning system','2011-02-19 07:51:58','2012-04-25 14:48:59','dsn=dbi:mysql:my:127.0.0.1:3306,dbuser=root,dbpass=,url_for_email=https://my.babelroom.com/users','no notes','provisioning',NULL);
INSERT INTO `systems` VALUES (2,'FreeSWITCH instance','2011-02-19 07:51:58','2012-04-25 14:41:55','hostname=127.0.0.1,ipv4=127.0.0.1,es_port=8888','No notes','freeswitch',NULL);
INSERT INTO `systems` VALUES (3,'Outbound SMTP server (Production)','2011-02-19 07:51:58','2011-05-18 07:51:26','disabled,mail_gw=SMTP/vps.babelroom.com:25','No notes','outbound_email',NULL);
INSERT INTO `systems` VALUES (4,'Outbound SMTP server (Development)','2011-02-19 07:51:58','2011-02-19 07:51:58','disabled,smtp_server=127.0.0.1:10025','No notes','outbound_email',NULL);
INSERT INTO `systems` VALUES (6,'Amazon s3 Storage','2011-03-06 06:53:21','2012-08-21 03:07:06','not_disabled,AWSAccessKeyId=AKIAIXSVMO3QOE72AN5Q,AWSSecretAccessKey=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,Bucket=bblr-conference_recordings,URLPrefix=https://s3.amazonaws.com','','s3',NULL);
INSERT INTO `systems` VALUES (7,'CheddarGetter Gateway','2011-04-28 06:46:56','2011-05-01 21:46:56','disabled,user=jroy@babelroom.net,pass=this37good','','cheddargetter',NULL);
INSERT INTO `systems` VALUES (8,'Recurly (sandbox)','2011-05-03 05:38:41','2012-04-19 15:56:19','not_disabled,url=https://api-sandbox.recurly.com/,auth_user=api-test@babelroom-test.com,auth_pass=0f5c640857e343cfab9ccddd7753fa92,account_prefix=P','','recurly',NULL);
INSERT INTO `systems` VALUES (9,'Gmail','2011-05-18 07:53:38','2012-04-25 14:37:48','not_disabled,mail_gw=Gmail/notifications@babelroom.com/c4lpqK2e','No notes','outbound_email',NULL);
INSERT INTO `systems` VALUES (11,'Pricing Plan','2011-08-24 01:48:00','2011-08-24 02:51:02','pool=100,in=29000/pool,inintl=29000/pool,out=29000/pool,outintl=29000/pool,tollfree=69000/0,webcall=0','','plans','free');
INSERT INTO `systems` VALUES (12,'Pricing Plan','2011-08-24 01:48:47','2011-09-01 19:07:10','pool=10,in=29000/pool,inintl=29000/pool,out=29000/pool,outintl=29000/pool,tollfree=69000/0,webcall=100000','','plans','solo_plan');
INSERT INTO `systems` VALUES (13,'Pricing Plan','2011-08-24 01:48:56','2011-08-24 01:49:53','pool=5000,in=19000/pool,inintl=19000/pool,out=19000/pool,outintl=19000/pool,tollfree=59000/0,webcall=0','','plans','pro_plan');
INSERT INTO `systems` VALUES (14,'Pricing Plan','2011-08-24 01:49:01','2011-08-24 01:50:15','inintl=19000/pool,out=19000/pool,outintl=19000/pool,tollfree=49000/0,webcall=0','','plans','flex_plan');
/*!40000 ALTER TABLE `systems` ENABLE KEYS */;
UNLOCK TABLES;

-- users for netops admin UI
DELETE FROM `users`;
ALTER TABLE `users` AUTO_INCREMENT=1;

DELETE FROM `webhooks`;
ALTER TABLE `webhooks` AUTO_INCREMENT=1;

