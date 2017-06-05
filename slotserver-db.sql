-- MySQL dump 10.13  Distrib 5.5.40, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: teamdev
-- ------------------------------------------------------
-- Server version	5.5.40-0ubuntu0.14.04.1

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
-- Table structure for table `Log_1`
--

DROP TABLE IF EXISTS `Log_1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Log_1` (
  `SessionID` bigint(20) unsigned NOT NULL,
  `Gen` int(10) unsigned NOT NULL,
  `GameData` text,
  `SpinsLeft` smallint(5) unsigned NOT NULL,
  `SpinsTotal` smallint(5) unsigned NOT NULL,
  `SecsLeft` smallint(5) unsigned NOT NULL,
  `SecsTotal` smallint(5) unsigned NOT NULL,
  `WinCurrent` int(10) unsigned NOT NULL,
  `WinTotal` bigint(20) unsigned NOT NULL,
  `CreateTime` bigint(20) unsigned NOT NULL,
  `ReelOffsets` binary(11) NOT NULL,
  `FSTriggers` binary(13) DEFAULT NULL,
  PRIMARY KEY (`SessionID`,`Gen`,`CreateTime`),
  KEY `SessionID` (`SessionID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1
/*!50100 PARTITION BY RANGE (( CreateTime DIV 3600000 ) MOD 24)
(PARTITION p0 VALUES LESS THAN (1) ENGINE = InnoDB,
 PARTITION p1 VALUES LESS THAN (2) ENGINE = InnoDB,
 PARTITION p2 VALUES LESS THAN (3) ENGINE = InnoDB,
 PARTITION p3 VALUES LESS THAN (4) ENGINE = InnoDB,
 PARTITION p4 VALUES LESS THAN (5) ENGINE = InnoDB,
 PARTITION p5 VALUES LESS THAN (6) ENGINE = InnoDB,
 PARTITION p6 VALUES LESS THAN (7) ENGINE = InnoDB,
 PARTITION p7 VALUES LESS THAN (8) ENGINE = InnoDB,
 PARTITION p8 VALUES LESS THAN (9) ENGINE = InnoDB,
 PARTITION p9 VALUES LESS THAN (10) ENGINE = InnoDB,
 PARTITION p10 VALUES LESS THAN (11) ENGINE = InnoDB,
 PARTITION p11 VALUES LESS THAN (12) ENGINE = InnoDB,
 PARTITION p12 VALUES LESS THAN (13) ENGINE = InnoDB,
 PARTITION p13 VALUES LESS THAN (14) ENGINE = InnoDB,
 PARTITION p14 VALUES LESS THAN (15) ENGINE = InnoDB,
 PARTITION p15 VALUES LESS THAN (16) ENGINE = InnoDB,
 PARTITION p16 VALUES LESS THAN (17) ENGINE = InnoDB,
 PARTITION p17 VALUES LESS THAN (18) ENGINE = InnoDB,
 PARTITION p18 VALUES LESS THAN (19) ENGINE = InnoDB,
 PARTITION p19 VALUES LESS THAN (20) ENGINE = InnoDB,
 PARTITION p20 VALUES LESS THAN (21) ENGINE = InnoDB,
 PARTITION p21 VALUES LESS THAN (22) ENGINE = InnoDB,
 PARTITION p22 VALUES LESS THAN (23) ENGINE = InnoDB,
 PARTITION p23 VALUES LESS THAN (24) ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Log_1`
--

LOCK TABLES `Log_1` WRITE;
/*!40000 ALTER TABLE `Log_1` DISABLE KEYS */;
/*!40000 ALTER TABLE `Log_1` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Players`
--

DROP TABLE IF EXISTS `Players`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Players` (
  `PlayerID` bigint(20) unsigned NOT NULL,
  `TournamentID` int(10) unsigned NOT NULL,
  `Token` char(40) DEFAULT NULL,
  `SessionID` bigint(20) unsigned DEFAULT NULL,
  `TournamentList` text,
  `ScreenName` char(25) DEFAULT '',
  `FacebookID` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`PlayerID`),
  UNIQUE KEY `Token` (`Token`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Players`
--

LOCK TABLES `Players` WRITE;
/*!40000 ALTER TABLE `Players` DISABLE KEYS */;
/*!40000 ALTER TABLE `Players` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Session_1`
--

DROP TABLE IF EXISTS `Session_1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Session_1` (
  `SessionID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `Token` char(40) DEFAULT NULL,
  `PlayerID` bigint(20) unsigned DEFAULT NULL,
  `GameID` int(10) unsigned DEFAULT NULL,
  `StartTime` bigint(20) NOT NULL,
  PRIMARY KEY (`SessionID`),
  KEY `Token` (`Token`),
  KEY `Player` (`PlayerID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1
/*!50100 PARTITION BY RANGE ( SessionID MOD 24)
(PARTITION p0 VALUES LESS THAN (1) ENGINE = InnoDB,
 PARTITION p1 VALUES LESS THAN (2) ENGINE = InnoDB,
 PARTITION p2 VALUES LESS THAN (3) ENGINE = InnoDB,
 PARTITION p3 VALUES LESS THAN (4) ENGINE = InnoDB,
 PARTITION p4 VALUES LESS THAN (5) ENGINE = InnoDB,
 PARTITION p5 VALUES LESS THAN (6) ENGINE = InnoDB,
 PARTITION p6 VALUES LESS THAN (7) ENGINE = InnoDB,
 PARTITION p7 VALUES LESS THAN (8) ENGINE = InnoDB,
 PARTITION p8 VALUES LESS THAN (9) ENGINE = InnoDB,
 PARTITION p9 VALUES LESS THAN (10) ENGINE = InnoDB,
 PARTITION p10 VALUES LESS THAN (11) ENGINE = InnoDB,
 PARTITION p11 VALUES LESS THAN (12) ENGINE = InnoDB,
 PARTITION p12 VALUES LESS THAN (13) ENGINE = InnoDB,
 PARTITION p13 VALUES LESS THAN (14) ENGINE = InnoDB,
 PARTITION p14 VALUES LESS THAN (15) ENGINE = InnoDB,
 PARTITION p15 VALUES LESS THAN (16) ENGINE = InnoDB,
 PARTITION p16 VALUES LESS THAN (17) ENGINE = InnoDB,
 PARTITION p17 VALUES LESS THAN (18) ENGINE = InnoDB,
 PARTITION p18 VALUES LESS THAN (19) ENGINE = InnoDB,
 PARTITION p19 VALUES LESS THAN (20) ENGINE = InnoDB,
 PARTITION p20 VALUES LESS THAN (21) ENGINE = InnoDB,
 PARTITION p21 VALUES LESS THAN (22) ENGINE = InnoDB,
 PARTITION p22 VALUES LESS THAN (23) ENGINE = InnoDB,
 PARTITION p23 VALUES LESS THAN (24) ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Session_1`
--

LOCK TABLES `Session_1` WRITE;
/*!40000 ALTER TABLE `Session_1` DISABLE KEYS */;
/*!40000 ALTER TABLE `Session_1` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `SlotGame`
--

DROP TABLE IF EXISTS `SlotGame`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SlotGame` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `Name` varchar(100) NOT NULL,
  `Theme` varchar(50) NOT NULL,
  `Math` varchar(50) NOT NULL,
  `StartTime` time NOT NULL,
  `EndTime` time NOT NULL,
  `SpinsTotal` smallint(5) unsigned NOT NULL,
  `SecsTotal` mediumint(8) unsigned NOT NULL,
  `CreateDate` datetime NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `SlotGame`
--

LOCK TABLES `SlotGame` WRITE;
/*!40000 ALTER TABLE `SlotGame` DISABLE KEYS */;
INSERT INTO `SlotGame` VALUES (1,'Angry Chefs','angrychefs','angrychefs','00:00:00','23:59:59',100,360,'0000-00-00 00:00:00'),(2,'Bankroll Bandits','bankrollbandits','bankrollbandits','00:00:00','23:59:59',100,420,'0000-00-00 00:00:00'),(3,'Butterfly Treasures','butterflytreasures','butterflytreasures','00:00:00','23:59:59',100,420,'0000-00-00 00:00:00'),(4,'Undersea World','underseaworld','underseaworld','00:00:00','23:59:59',5,420,'0000-00-00 00:00:00'),(5,'Romancing Riches','romancingriches','romancingriches','00:00:00','23:59:59',100,120,'2014-12-07 22:06:47');
/*!40000 ALTER TABLE `SlotGame` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `SlotServer`
--

DROP TABLE IF EXISTS `SlotServer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SlotServer` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `Host` varchar(200) NOT NULL,
  `Port` int(10) unsigned NOT NULL,
  `CryptoOn` tinyint(3) unsigned NOT NULL,
  `CryptoKey` varchar(100) NOT NULL,
  `Debug` tinyint(3) unsigned NOT NULL,
  `MathList` text NOT NULL,
  `MaxConnections` int(10) unsigned NOT NULL,
  `StartDate` datetime NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `SlotServer`
--

LOCK TABLES `SlotServer` WRITE;
/*!40000 ALTER TABLE `SlotServer` DISABLE KEYS */;
/*!40000 ALTER TABLE `SlotServer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `SlotTournament`
--

DROP TABLE IF EXISTS `SlotTournament`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SlotTournament` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `StartDate` datetime DEFAULT NULL,
  `EndDate` datetime DEFAULT NULL,
  `PrizeList` text,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `SlotTournament`
--

LOCK TABLES `SlotTournament` WRITE;
/*!40000 ALTER TABLE `SlotTournament` DISABLE KEYS */;
INSERT INTO `SlotTournament` VALUES (1,'2012-11-10 10:15:00','2015-12-10 10:25:00','\"A PURPLE PONY\"');
/*!40000 ALTER TABLE `SlotTournament` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-01-29  9:20:22
