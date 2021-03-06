CREATE DATABASE xzb CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER user_2013;

SET PASSWORD FOR user_2013 = PASSWORD("ilovechina");

GRANT ALL PRIVILEGES ON xzb.* TO "user_2013"@"localhost" IDENTIFIED BY "ilovechina";

FLUSH PRIVILEGES;

use xzb;
CREATE TABLE if not exists posts (
       num int primary key AUTO_INCREMENT,
       postid CHAR(40) NOT NULL unique,
       category VARCHAR(50) NOT NULL,
       title VARCHAR(200) NOT NULL,
       filename VARCHAR(200) NOT NULL,
       voteup int default 0,
       votedown int default 0,
       memo VARCHAR(100)
);

-- DROP INDEX index_voteup ON posts;
-- DROP INDEX index_votedown ON posts;

CREATE INDEX index_voteup ON posts(voteup) USING btree;
CREATE INDEX index_votedown ON posts(votedown) USING btree;