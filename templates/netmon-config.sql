SET CHARSET "utf8";

INSERT INTO `config` VALUES
(1,'url_to_netmon','http://<%= @netmon_domain %>/','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(2,'community_name','Freifunk <%= @city_name %>','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(3,'community_slogan','Die freie WLAN-Community aus <%= @city_name %> • Freie Netze für alle!','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(4,'community_location_longitude','<%= @map_lng %>','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(5,'community_location_latitude','<%= @map_lat %>','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(6,'community_location_zoom','<%= @map_zoom %>','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(7,'mail_sender_adress','<%= @mail_sender_address %>','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(8,'mail_sender_name','Netmon Freifunk <%= @city_name %>','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(9,'mail_sending_type','php_mail','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(10,'mail_smtp_server','','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(11,'mail_smtp_username','','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(12,'mail_smtp_password','','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(13,'mail_smtp_login_auth','','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(14,'mail_smtp_ssl','','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(15,'twitter_consumer_key','dRWT5eeIn9UiHJgcjgpPQ','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(16,'twitter_consumer_secret','QxcnltPX2sTH8E7eZlxyZeqTIVoIoRjlrmUfkCzGSA','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(17,'enable_network_policy','false','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(18,'network_policy_url','http://picopeer.net/PPA-de.html','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(19,'template','freifunk_oldenburg','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(20,'hours_to_keep_mysql_crawl_data','5','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(21,'hours_to_keep_history_table','72','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(22,'crawl_cycle_length_in_minutes','10','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(23,'event_notification_router_offline_crawl_cycles','6','2014-10-05 23:55:43','0000-00-00 00:00:00'),
(24,'community_essid','<%= @community_essid %>', '2014-10-05 23:55:43','0000-00-00 00:00:00'),
(26, 'network_connection_ipv6', 'true', '2014-10-05 23:55:43','0000-00-00 00:00:00'), 
(27, 'network_connection_ipv6_interface', 'br_<%= @community %>', '2014-10-05 23:55:43','0000-00-00 00:00:00');

INSERT INTO `chipsets` (`id`, `create_date`, `update_date`, `name`, `hardware_name`) VALUES
(1, '2014-10-07 21:57:22', '2014-10-07 21:57:22', '', 'Unbekannt');

INSERT INTO `crawl_cycle` (`id`, `crawl_date`, `crawl_date_end`) VALUES
(1, '2014-10-07 21:47:22', '0000-00-00 00:00:00');

INSERT INTO `users` (`id`, `nickname`, `password`, `api_key`, `email`, `permission`, `create_date`, `activated`) VALUES
(1, '<%= @admin_nickname%>', '<%= @admin_password %>', '<%= @admin_apikey %>', '<%= @admin_email %>', 120, NOW(), 0);

INSERT INTO `networks` (`id`, `user_id`, `ip`, `netmask`, `ipv`, `create_date`, `update_date`) VALUES
(1, 1, 'fe80:0000:0000:0000:0000:0000:0000:0000', 64, 6, '2014-10-07 22:46:53', '2014-10-07 22:46:53');

