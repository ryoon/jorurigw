-- MySQL dump 10.13  Distrib 5.1.30, for pc-linux-gnu (i686)
--
-- Host: localhost    Database: development_jgw_bbs_000001
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
-- Dumping data for table `gwbbs_categories`
--

LOCK TABLES `gwbbs_categories` WRITE;
/*!40000 ALTER TABLE `gwbbs_categories` DISABLE KEYS */;
INSERT INTO `gwbbs_categories` VALUES (1,NULL,NULL,'public','2011-05-23 21:59:33','2011-05-23 21:59:33',1,1,1,'お知らせ'),(2,NULL,NULL,'public','2011-05-23 22:01:21','2011-05-23 22:02:00',1,2,1,'研修案内'),(3,NULL,NULL,'public','2011-05-23 22:01:45','2011-05-23 22:01:45',1,3,1,'行事予定（イベント案内）'),(4,NULL,NULL,'public','2011-05-23 22:02:50','2011-05-23 22:02:50',1,4,1,'全庁通知'),(5,NULL,NULL,'public','2011-05-23 22:03:40','2011-05-23 22:03:40',1,5,1,'調査・照会'),(6,NULL,NULL,'public','2011-05-23 22:04:12','2011-05-23 22:04:12',1,6,1,'福利厚生関係(1)'),(7,NULL,NULL,'public','2011-05-23 22:05:44','2011-05-23 22:05:44',1,7,1,'その他');
/*!40000 ALTER TABLE `gwbbs_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `gwbbs_comments`
--

LOCK TABLES `gwbbs_comments` WRITE;
/*!40000 ALTER TABLE `gwbbs_comments` DISABLE KEYS */;
/*!40000 ALTER TABLE `gwbbs_comments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `gwbbs_db_files`
--

LOCK TABLES `gwbbs_db_files` WRITE;
/*!40000 ALTER TABLE `gwbbs_db_files` DISABLE KEYS */;
/*!40000 ALTER TABLE `gwbbs_db_files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `gwbbs_docs`
--

LOCK TABLES `gwbbs_docs` WRITE;
/*!40000 ALTER TABLE `gwbbs_docs` DISABLE KEYS */;
/*!40000 ALTER TABLE `gwbbs_docs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `gwbbs_files`
--

LOCK TABLES `gwbbs_files` WRITE;
/*!40000 ALTER TABLE `gwbbs_files` DISABLE KEYS */;
/*!40000 ALTER TABLE `gwbbs_files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `gwbbs_images`
--

LOCK TABLES `gwbbs_images` WRITE;
/*!40000 ALTER TABLE `gwbbs_images` DISABLE KEYS */;
/*!40000 ALTER TABLE `gwbbs_images` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `gwbbs_recognizers`
--

LOCK TABLES `gwbbs_recognizers` WRITE;
/*!40000 ALTER TABLE `gwbbs_recognizers` DISABLE KEYS */;
/*!40000 ALTER TABLE `gwbbs_recognizers` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-05-23 13:06:12
