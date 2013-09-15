-- MySQL dump 10.13  Distrib 5.1.30, for pc-linux-gnu (i686)
--
-- Host: localhost    Database: development_jgw_core
-- ------------------------------------------------------
-- Server version	5.1.30

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `cms_content_mappings`
--

DROP TABLE IF EXISTS `cms_content_mappings`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_content_mappings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) DEFAULT NULL,
  `content_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `creator_user_id` int(11) DEFAULT NULL,
  `creator_group_id` int(11) DEFAULT NULL,
  `state_no` int(11) DEFAULT NULL,
  `sort_no` int(11) DEFAULT NULL,
  `admin_display_no` int(11) DEFAULT NULL,
  `sitemap_display_no` int(11) NOT NULL,
  `navi_display_no` int(11) NOT NULL,
  `title` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cms_content_pages`
--

DROP TABLE IF EXISTS `cms_content_pages`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_content_pages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `content_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `creator_user_id` int(11) DEFAULT NULL,
  `creator_group_id` int(11) DEFAULT NULL,
  `state_no` int(11) DEFAULT NULL,
  `sort_no` int(11) DEFAULT NULL,
  `published` datetime DEFAULT NULL,
  `closed` datetime DEFAULT NULL,
  `publish_date` datetime DEFAULT NULL,
  `close_date` datetime DEFAULT NULL,
  `name` text,
  `title` text,
  `head` mediumtext,
  `body` mediumtext,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cms_contents`
--

DROP TABLE IF EXISTS `cms_contents`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_contents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `module` text,
  `controller` text,
  `name` text,
  `title` text,
  `path` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=128 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cms_files`
--

DROP TABLE IF EXISTS `cms_files`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_files` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `parent_unid` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `name` text,
  `title` text,
  `mime_type` text,
  `size` int(11) DEFAULT NULL,
  `image_is` int(11) DEFAULT NULL,
  `image_width` int(11) DEFAULT NULL,
  `image_height` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cms_layouts`
--

DROP TABLE IF EXISTS `cms_layouts`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_layouts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `recognized_at` datetime DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `name` text,
  `title` text,
  `head` mediumtext,
  `body` mediumtext,
  `stylesheet` mediumtext,
  `mobile_head` mediumtext,
  `mobile_body` mediumtext,
  `mobile_stylesheet` mediumtext,
  `s_mobile_head` mediumtext,
  `s_mobile_body` mediumtext,
  `s_mobile_stylesheet` mediumtext,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=171 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cms_maps`
--

DROP TABLE IF EXISTS `cms_maps`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_maps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `sort_no` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `node_id` int(11) DEFAULT NULL,
  `title` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=219 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cms_nodes`
--

DROP TABLE IF EXISTS `cms_nodes`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_nodes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `recognized_at` datetime DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `content_id` int(11) DEFAULT NULL,
  `layout_id` int(11) DEFAULT NULL,
  `controller` text,
  `name` text,
  `title` text,
  PRIMARY KEY (`id`),
  KEY `parent_id` (`parent_id`,`name`(20))
) ENGINE=MyISAM AUTO_INCREMENT=719 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cms_pages`
--

DROP TABLE IF EXISTS `cms_pages`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_pages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `recognized_at` datetime DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `node_id` int(11) DEFAULT NULL,
  `layout_id` int(11) DEFAULT NULL,
  `name` text,
  `title` text,
  `head` mediumtext,
  `body` mediumtext,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=256 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cms_piece_links`
--

DROP TABLE IF EXISTS `cms_piece_links`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_piece_links` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `recognized_at` datetime DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `piece_id` int(11) DEFAULT NULL,
  `sort_no` int(11) DEFAULT NULL,
  `title` text,
  `body` mediumtext,
  `url` text,
  `target` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cms_pieces`
--

DROP TABLE IF EXISTS `cms_pieces`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_pieces` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `recognized_at` datetime DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `content_id` int(11) DEFAULT NULL,
  `controller` text,
  `outline` text,
  `name` text,
  `title` text,
  `head` mediumtext,
  `body` mediumtext,
  PRIMARY KEY (`id`),
  KEY `name` (`name`(50),`state`(10))
) ENGINE=MyISAM AUTO_INCREMENT=187 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cms_routes`
--

DROP TABLE IF EXISTS `cms_routes`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_routes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `sort_no` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `node_id` int(11) DEFAULT NULL,
  `title` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cms_sites`
--

DROP TABLE IF EXISTS `cms_sites`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_sites` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `domain` text,
  `name` text,
  `node_id` int(11) DEFAULT NULL,
  `mobile_is` int(11) DEFAULT NULL,
  `mobile_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cms_texts`
--

DROP TABLE IF EXISTS `cms_texts`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_texts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `recognized_at` datetime DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `module` text,
  `controller` text,
  `name` text,
  `title` text,
  `body` mediumtext,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cms_tmp_file_groups`
--

DROP TABLE IF EXISTS `cms_tmp_file_groups`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_tmp_file_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tmp_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `name` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `cms_tmp_files`
--

DROP TABLE IF EXISTS `cms_tmp_files`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `cms_tmp_files` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tmp_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `name` text,
  `title` text,
  `mime_type` text,
  `size` int(11) DEFAULT NULL,
  `image_is` int(11) DEFAULT NULL,
  `image_width` int(11) DEFAULT NULL,
  `image_height` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `intra_maintenances`
--

DROP TABLE IF EXISTS `intra_maintenances`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `intra_maintenances` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `title` text,
  `body` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `intra_messages`
--

DROP TABLE IF EXISTS `intra_messages`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `intra_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `title` text,
  `body` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(255) NOT NULL,
  `data` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_admin_logs`
--

DROP TABLE IF EXISTS `system_admin_logs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_admin_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `item_unid` int(11) DEFAULT NULL,
  `controller` text,
  `action` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `system_authorizations`
--

DROP TABLE IF EXISTS `system_authorizations`;
/*!50001 DROP VIEW IF EXISTS `system_authorizations`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `system_authorizations` (
  `user_id` int(11),
  `user_code` varchar(255),
  `user_name` text,
  `user_name_en` text,
  `user_password` text,
  `user_email` text,
  `remember_token` text,
  `remember_token_expires_at` datetime,
  `group_id` int(11),
  `group_code` varchar(255),
  `group_name` text,
  `group_name_en` text,
  `group_email` text
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_commitments`
--

DROP TABLE IF EXISTS `system_commitments`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_commitments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `version` text,
  `name` text,
  `value` longtext,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_creators`
--

DROP TABLE IF EXISTS `system_creators`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_creators` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `unid` int(11) DEFAULT NULL,
  `user_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3522 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_custom_group_roles`
--

DROP TABLE IF EXISTS `system_custom_group_roles`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_custom_group_roles` (
  `rid` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `custom_group_id` int(11) DEFAULT NULL,
  `priv_name` text,
  `user_id` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`rid`),
  KEY `custom_group_id` (`custom_group_id`)
) ENGINE=MyISAM AUTO_INCREMENT=28241 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_custom_groups`
--

DROP TABLE IF EXISTS `system_custom_groups`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_custom_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `owner_uid` int(11) DEFAULT NULL,
  `owner_gid` int(11) DEFAULT NULL,
  `updater_uid` int(11) NOT NULL,
  `updater_gid` int(11) NOT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `level_no` int(11) DEFAULT NULL,
  `name` text,
  `name_en` text,
  `sort_no` int(11) DEFAULT NULL,
  `sort_prefix` text,
  `is_default` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_group_change_pickups`
--

DROP TABLE IF EXISTS `system_group_change_pickups`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_group_change_pickups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `target_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=11 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_group_changes`
--

DROP TABLE IF EXISTS `system_group_changes`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_group_changes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `state` text,
  `target_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_group_histories`
--

DROP TABLE IF EXISTS `system_group_histories`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_group_histories` (
  `id` int(11) NOT NULL DEFAULT '0',
  `parent_id` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `level_no` int(11) DEFAULT NULL,
  `version_id` int(11) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL COMMENT 'group_code',
  `name` text,
  `name_en` text,
  `email` text,
  `start_at` datetime DEFAULT NULL,
  `end_at` datetime DEFAULT NULL,
  `sort_no` int(11) DEFAULT NULL,
  `ldap_version` varchar(255) DEFAULT NULL,
  `ldap` int(11) DEFAULT NULL COMMENT 'ldap_flg'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_group_histories_back`
--

DROP TABLE IF EXISTS `system_group_histories_back`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_group_histories_back` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `level_no` int(11) DEFAULT NULL,
  `version_id` int(11) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL COMMENT 'group_code',
  `name` text,
  `name_en` text,
  `email` text,
  `start_at` datetime DEFAULT NULL,
  `end_at` datetime DEFAULT NULL,
  `sort_no` int(11) DEFAULT NULL,
  `ldap_version` varchar(255) DEFAULT NULL,
  `ldap` int(11) DEFAULT NULL COMMENT 'ldap_flg',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_group_history_temporaries`
--

DROP TABLE IF EXISTS `system_group_history_temporaries`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_group_history_temporaries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `level_no` int(11) DEFAULT NULL,
  `version_id` int(11) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL COMMENT 'group_code',
  `name` text,
  `name_en` text,
  `email` text,
  `start_at` datetime DEFAULT NULL,
  `end_at` datetime DEFAULT NULL,
  `sort_no` int(11) DEFAULT NULL,
  `ldap_version` varchar(255) DEFAULT NULL,
  `ldap` int(11) DEFAULT NULL COMMENT 'ldap_flg',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_group_nexts`
--

DROP TABLE IF EXISTS `system_group_nexts`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_group_nexts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_update_id` int(11) DEFAULT NULL,
  `operation` text,
  `old_group_id` int(11) DEFAULT NULL,
  `old_code` text,
  `old_name` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `old_parent_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_group_temporaries`
--

DROP TABLE IF EXISTS `system_group_temporaries`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_group_temporaries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `level_no` int(11) DEFAULT NULL,
  `version_id` int(11) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL COMMENT 'group_code',
  `name` text,
  `name_en` text,
  `email` text,
  `start_at` datetime DEFAULT NULL,
  `end_at` datetime DEFAULT NULL,
  `sort_no` int(11) DEFAULT NULL,
  `ldap_version` varchar(255) DEFAULT NULL,
  `ldap` int(11) DEFAULT NULL COMMENT 'ldap_flg',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_group_updates`
--

DROP TABLE IF EXISTS `system_group_updates`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_group_updates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_code` text,
  `parent_name` text,
  `level_no` int(11) DEFAULT NULL,
  `code` text,
  `name` text,
  `state` text,
  `start_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_group_versions`
--

DROP TABLE IF EXISTS `system_group_versions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_group_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  `start_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_groups`
--

DROP TABLE IF EXISTS `system_groups`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `level_no` int(11) DEFAULT NULL,
  `version_id` int(11) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL COMMENT 'group_code',
  `name` text,
  `name_en` text,
  `email` text,
  `start_at` datetime DEFAULT NULL,
  `end_at` datetime DEFAULT NULL,
  `sort_no` int(11) DEFAULT NULL,
  `ldap_version` varchar(255) DEFAULT NULL,
  `ldap` int(11) DEFAULT NULL COMMENT 'ldap_flg',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=727 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_groups_back`
--

DROP TABLE IF EXISTS `system_groups_back`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_groups_back` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `level_no` int(11) DEFAULT NULL,
  `version_id` int(11) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL COMMENT 'group_code',
  `name` text,
  `name_en` text,
  `email` text,
  `start_at` datetime DEFAULT NULL,
  `end_at` datetime DEFAULT NULL,
  `sort_no` int(11) DEFAULT NULL,
  `ldap_version` varchar(255) DEFAULT NULL,
  `ldap` int(11) DEFAULT NULL COMMENT 'ldap_flg',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_idconversions`
--

DROP TABLE IF EXISTS `system_idconversions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_idconversions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `tablename` text,
  `modelname` varchar(255) DEFAULT NULL,
  `converted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_inquiries`
--

DROP TABLE IF EXISTS `system_inquiries`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_inquiries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `charge` text,
  `tel` text,
  `fax` text,
  `email` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=278 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_languages`
--

DROP TABLE IF EXISTS `system_languages`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_languages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `sort_no` int(11) DEFAULT NULL,
  `name` text,
  `title` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_ldap_temporaries`
--

DROP TABLE IF EXISTS `system_ldap_temporaries`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_ldap_temporaries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `version` varchar(255) DEFAULT NULL,
  `data_type` varchar(255) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL,
  `sort_no` varchar(255) DEFAULT NULL,
  `name` text,
  `name_en` text,
  `kana` text,
  `email` text,
  `match` text,
  `offitial_position` varchar(255) DEFAULT NULL,
  `assigned_job` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `version` (`version`(20),`parent_id`,`data_type`(20),`sort_no`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_login_logs`
--

DROP TABLE IF EXISTS `system_login_logs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_login_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_maps`
--

DROP TABLE IF EXISTS `system_maps`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_maps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `name` text,
  `title` text,
  `map_lat` text,
  `map_lng` text,
  `map_zoom` text,
  `point1_name` text,
  `point1_lat` text,
  `point1_lng` text,
  `point2_name` text,
  `point2_lat` text,
  `point2_lng` text,
  `point3_name` text,
  `point3_lat` text,
  `point3_lng` text,
  `point4_name` text,
  `point4_lat` text,
  `point4_lng` text,
  `point5_name` text,
  `point5_lat` text,
  `point5_lng` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_priv_names`
--

DROP TABLE IF EXISTS `system_priv_names`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_priv_names` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text,
  `content_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `display_name` text,
  `priv_name` text,
  `sort_no` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_public_logs`
--

DROP TABLE IF EXISTS `system_public_logs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_public_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `item_unid` int(11) DEFAULT NULL,
  `controller` text,
  `action` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_publishers`
--

DROP TABLE IF EXISTS `system_publishers`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_publishers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `name` text,
  `published_path` text,
  `content_type` text,
  `content_length` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_recognitions`
--

DROP TABLE IF EXISTS `system_recognitions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_recognitions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `after_process` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_recognizers`
--

DROP TABLE IF EXISTS `system_recognizers`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_recognizers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `name` text NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `recognized_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_role_developers`
--

DROP TABLE IF EXISTS `system_role_developers`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_role_developers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `idx` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `uid` varchar(255) DEFAULT NULL,
  `priv` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `role_name_id` int(11) DEFAULT NULL,
  `table_name` text,
  `priv_name` text,
  `priv_user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_role_name_privs`
--

DROP TABLE IF EXISTS `system_role_name_privs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_role_name_privs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `role_id` int(11) DEFAULT NULL,
  `priv_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=209 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_role_names`
--

DROP TABLE IF EXISTS `system_role_names`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_role_names` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `state` text,
  `content_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `display_name` text,
  `table_name` text,
  `sort_no` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=56 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_roles`
--

DROP TABLE IF EXISTS `system_roles`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `table_name` varchar(255) DEFAULT NULL,
  `priv_name` varchar(255) DEFAULT NULL,
  `idx` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `uid` varchar(255) DEFAULT NULL,
  `priv` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `role_name_id` int(11) DEFAULT NULL,
  `priv_user_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_sequences`
--

DROP TABLE IF EXISTS `system_sequences`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_sequences` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `name` text,
  `version` int(11) DEFAULT NULL,
  `value` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_tags`
--

DROP TABLE IF EXISTS `system_tags`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_tags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `name` text,
  `word` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_tasks`
--

DROP TABLE IF EXISTS `system_tasks`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_tasks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unid` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `process_at` datetime DEFAULT NULL,
  `name` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_unids`
--

DROP TABLE IF EXISTS `system_unids`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_unids` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `module` text,
  `item_type` text,
  `item_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3446 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_user_temporaries`
--

DROP TABLE IF EXISTS `system_user_temporaries`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_user_temporaries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `air_login_id` varchar(255) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `code` varchar(255) NOT NULL,
  `ldap` int(11) NOT NULL,
  `ldap_version` int(11) DEFAULT NULL,
  `auth_no` text,
  `sort_no` varchar(255) DEFAULT NULL,
  `name` text,
  `name_en` text,
  `kana` text,
  `password` text,
  `mobile_access` int(11) DEFAULT NULL,
  `mobile_password` varchar(255) DEFAULT NULL,
  `email` text,
  `offitial_position` varchar(255) DEFAULT NULL,
  `assigned_job` varchar(255) DEFAULT NULL,
  `remember_token` text,
  `remember_token_expires_at` datetime DEFAULT NULL,
  `air_token` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_code` (`code`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_users`
--

DROP TABLE IF EXISTS `system_users`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `air_login_id` varchar(255) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `code` varchar(255) NOT NULL,
  `ldap` int(11) NOT NULL,
  `ldap_version` int(11) DEFAULT NULL,
  `auth_no` text,
  `sort_no` varchar(255) DEFAULT NULL,
  `name` text,
  `name_en` text,
  `kana` text,
  `password` text,
  `mobile_access` int(11) DEFAULT NULL,
  `mobile_password` varchar(255) DEFAULT NULL,
  `email` text,
  `offitial_position` varchar(255) DEFAULT NULL,
  `assigned_job` varchar(255) DEFAULT NULL,
  `remember_token` text,
  `remember_token_expires_at` datetime DEFAULT NULL,
  `air_token` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_code` (`code`)
) ENGINE=MyISAM AUTO_INCREMENT=5478 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_users_back`
--

DROP TABLE IF EXISTS `system_users_back`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_users_back` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `air_login_id` varchar(255) DEFAULT NULL,
  `state` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `code` varchar(255) NOT NULL,
  `ldap` int(11) NOT NULL,
  `ldap_version` int(11) DEFAULT NULL,
  `auth_no` text,
  `sort_no` varchar(255) DEFAULT NULL,
  `name` text,
  `name_en` text,
  `kana` text,
  `password` text,
  `mobile_access` int(11) DEFAULT NULL,
  `mobile_password` varchar(255) DEFAULT NULL,
  `email` text,
  `offitial_position` varchar(255) DEFAULT NULL,
  `assigned_job` varchar(255) DEFAULT NULL,
  `remember_token` text,
  `remember_token_expires_at` datetime DEFAULT NULL,
  `air_token` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_code` (`code`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_users_custom_groups`
--

DROP TABLE IF EXISTS `system_users_custom_groups`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_users_custom_groups` (
  `rid` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `custom_group_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `title` text,
  `title_en` text,
  `sort_no` int(11) DEFAULT NULL,
  `icon` text,
  PRIMARY KEY (`rid`),
  KEY `custom_group_id` (`custom_group_id`)
) ENGINE=MyISAM AUTO_INCREMENT=38 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_users_group_histories`
--

DROP TABLE IF EXISTS `system_users_group_histories`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_users_group_histories` (
  `rid` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `job_order` int(11) DEFAULT NULL COMMENT '本務0・兼務1',
  `start_at` datetime DEFAULT NULL COMMENT '適用開始日',
  `end_at` datetime DEFAULT NULL,
  `user_code` varchar(255) DEFAULT NULL,
  `group_code` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=MyISAM AUTO_INCREMENT=23 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_users_group_histories_back`
--

DROP TABLE IF EXISTS `system_users_group_histories_back`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_users_group_histories_back` (
  `rid` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `job_order` int(11) DEFAULT NULL COMMENT '本務0・兼務1',
  `start_at` datetime DEFAULT NULL COMMENT '適用開始日',
  `end_at` datetime DEFAULT NULL,
  `user_code` varchar(255) DEFAULT NULL,
  `group_code` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_users_group_history_temporaries`
--

DROP TABLE IF EXISTS `system_users_group_history_temporaries`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_users_group_history_temporaries` (
  `rid` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `job_order` int(11) DEFAULT NULL COMMENT '本務0・兼務1',
  `start_at` datetime DEFAULT NULL COMMENT '適用開始日',
  `end_at` datetime DEFAULT NULL,
  `user_code` varchar(255) DEFAULT NULL,
  `group_code` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_users_group_temporaries`
--

DROP TABLE IF EXISTS `system_users_group_temporaries`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_users_group_temporaries` (
  `rid` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `job_order` int(11) DEFAULT NULL COMMENT '本務0・兼務1',
  `start_at` datetime DEFAULT NULL COMMENT '適用開始日',
  `end_at` datetime DEFAULT NULL,
  `user_code` varchar(255) DEFAULT NULL,
  `group_code` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_users_groups`
--

DROP TABLE IF EXISTS `system_users_groups`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_users_groups` (
  `rid` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `job_order` int(11) DEFAULT NULL COMMENT '本務0・兼務1',
  `start_at` datetime DEFAULT NULL COMMENT '適用開始日',
  `end_at` datetime DEFAULT NULL,
  `user_code` varchar(255) DEFAULT NULL,
  `group_code` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=MyISAM AUTO_INCREMENT=11865 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `system_users_groups_back`
--

DROP TABLE IF EXISTS `system_users_groups_back`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `system_users_groups_back` (
  `rid` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `job_order` int(11) DEFAULT NULL COMMENT '本務0・兼務1',
  `start_at` datetime DEFAULT NULL COMMENT '適用開始日',
  `end_at` datetime DEFAULT NULL,
  `user_code` varchar(255) DEFAULT NULL,
  `group_code` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Final view structure for view `system_authorizations`
--

/*!50001 DROP TABLE `system_authorizations`*/;
/*!50001 DROP VIEW IF EXISTS `system_authorizations`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50001 VIEW `system_authorizations` AS (select `users`.`id` AS `user_id`,`users`.`code` AS `user_code`,`users`.`name` AS `user_name`,`users`.`name_en` AS `user_name_en`,`users`.`password` AS `user_password`,`users`.`email` AS `user_email`,`users`.`remember_token` AS `remember_token`,`users`.`remember_token_expires_at` AS `remember_token_expires_at`,`groups`.`id` AS `group_id`,`groups`.`code` AS `group_code`,`groups`.`name` AS `group_name`,`groups`.`name_en` AS `group_name_en`,`groups`.`email` AS `group_email` from ((`system_users` `users` join `system_users_groups` `sug` on((`sug`.`user_id` = `users`.`id`))) join `system_groups` `groups` on((`groups`.`id` = `sug`.`group_id`))) where (`users`.`ldap` = 0)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-05-23  3:01:49
