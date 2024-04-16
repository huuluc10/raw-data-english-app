drop database if exists eng_learn_app;

create database if not exists eng_learn_app;

use eng_learn_app;

create table if not exists role
(
    role_id tinyint primary key auto_increment,
    name varchar(20) not null
);

create table if not exists media_type
(
    media_type_id tinyint primary key auto_increment,
    media_type_name varchar(30) not null
);

create table if not exists media
(
    media_id int primary key auto_increment,
    media_name varchar(100) not null,
    media_type_id tinyint not null,
    url text default null,
    foreign key(media_type_id) references media_type(media_type_id)
);

create table if not exists user
(
    username varchar(30) primary key,
    full_name varchar(70) not null,
    date_of_birth date not null,
    gender boolean default 1,
    email varchar(50) null,
    password varchar(100) not null,
    avatar int not null,
    role_id tinyint not null,
    streak int not null,
    experience int not null,
    date_created datetime default current_timestamp,
    foreign key(role_id) references role(role_id),
    foreign key(avatar) references media(media_id)
);

create table if not exists friend_request
(
    sender varchar(30) not null,
    receiver varchar(30) not null,
    status tinyint not null,
    primary key(sender, receiver),
    foreign key(sender) references user(username),
    foreign key(receiver) references user(username)
);

create table if not exists topic
(
    topic_id tinyint primary key auto_increment,
    topic_name varchar(200) not null
);

create table if not exists mission_daily
(
    mission_id tinyint primary key auto_increment,
    mission_name varchar(30) not null,
    mission_content varchar(100) not null,
    mission_experience int not null
);

create table if not exists level
(
    level_id tinyint primary key auto_increment,
    level_name varchar(30) not null,
    experience_threshold int not null
);

create table if not exists lesson
(
    lesson_id int primary key auto_increment,
    lesson_name varchar(100) not null,
    topic_id tinyint not null,
    content int not null,
    lesson_experience int not null,
    level_id tinyint not null,
    foreign key(topic_id) references topic(topic_id),
    foreign key(content) references media(media_id),
    foreign key(level_id) references level(level_id)
);

create table if not exists user_mission
(
    username varchar(30) not null,
    mission_id tinyint not null,
    date_done datetime default current_timestamp ,
    primary key(username, mission_id, date_done),
    foreign key(username) references user(username),
    foreign key(mission_id) references mission_daily(mission_id)
);

create table if not exists user_lesson
(
    username varchar(30) not null,
    lesson_id int not null,
    date_learned datetime default current_timestamp,
    primary key(username, lesson_id),
    foreign key(username) references user(username),
    foreign key(lesson_id) references lesson(lesson_id)
);

create table if not exists exam
(
    exam_id int primary key auto_increment,
    exam_name varchar(30) not null,
    exam_experience int not null,
    exam_level tinyint not null,
    topic_id tinyint not null,
    foreign key(topic_id) references topic(topic_id),
    foreign key(exam_level) references level(level_id)
);

create table if not exists question_type
(
    question_type_id tinyint primary key auto_increment,
    question_type_name varchar(30) not null
);

create table if not exists question
(
    question_id int primary key auto_increment,
    question_content varchar(100) not null,
    question_type_id tinyint not null,
    belong_to ENUM ('LESSON', 'EXAM') default 'LESSON',
    lesson_id int null,
    exam_id int null,
    answer int not null,
    foreign key (answer) references media(media_id),
    foreign key(exam_id) references exam(exam_id),
    foreign key(lesson_id) references lesson(lesson_id),
    foreign key(question_type_id) references question_type(question_type_id)
);

create table if not exists user_question
(
    username varchar(30) not null,
    question_id int not null,
    is_correct tinyint not null,
    date_done datetime default current_timestamp,
    primary key(username, question_id),
    foreign key(username) references user(username),
    foreign key(question_id) references question(question_id)
);

create table if not exists jwt_token_blacklist
(
    token varchar(255) primary key,
    expired_at datetime not null
);

create table if not exists code_verification
(
    email varchar(30) not null ,
    code varchar(6) not null,
    expired_at datetime not null,
    primary key(email, code)
);

DELIMITER $$
CREATE PROCEDURE if not exists sp_manage_code_verification
(
    IN p_email VARCHAR(30),
  IN p_code VARCHAR(255),
  IN p_expired_at DATETIME
)
BEGIN
  -- Thêm mã mới
  INSERT INTO code_verification (email, code, expired_at) VALUES (p_email, p_code, p_expired_at);

  -- Xóa mã đã hết hạn
  DELETE FROM code_verification
  WHERE expired_at < NOW() - INTERVAL 5 MINUTE;
END$$
DELIMITER ;

call sp_manage_code_verification('lucnguyenhuu91@gmail.com', '123456', now());

DELIMITER $$
CREATE EVENT IF NOT EXISTS delete_expired_code
ON SCHEDULE EVERY 30 MINUTE
DO
BEGIN
  DELETE FROM jwt_token_blacklist
  WHERE expired_at <= NOW();
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE IF NOT EXISTS getExamResult(IN username VARCHAR(50), IN exam_id INT)
BEGIN
    IF EXISTS(select * from user_question us join question q on us.question_id = q.question_id where us.username = username and q.exam_id = exam_id) THEN
        select (select count(us.question_id) from user_question us
        join question q on us.question_id = q.question_id
        where us.username = username and q.exam_id = exam_id and us.is_correct = 1) * 100 / (select count(us.question_id) from user_question us
        join question q on us.question_id = q.question_id
        where us.username = username and q.exam_id = exam_id) as result;
    ELSE
        select 0 as result;
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE IF NOT EXISTS getSummaryLessonOfTopic(IN username VARCHAR(50), IN topic_id INT)
BEGIN
  SELECT COUNT(ul.lesson_id) AS done,
         (SELECT COUNT(*) FROM lesson l
          INNER JOIN topic t ON l.topic_id = t.topic_id
          WHERE t.topic_id = topic_id) AS total
  FROM user_lesson ul
  INNER JOIN lesson l ON ul.lesson_id = l.lesson_id
  INNER JOIN topic t ON l.topic_id = t.topic_id
  WHERE ul.username = username AND t.topic_id = topic_id;
END$$
DELIMITER ;

insert into media_type(media_type_name) values ('Image'), ('Audio'), ('Video'), ('Json');

insert into role(name) values ('Admin'), ('User');

insert into level(level_name, experience_threshold) values ('Beginner', 0), ('Elementary', 300), ('Pre-Intermediate', 800),
                                                           ('Intermediate', 2000), ('Advanced', 4500);

insert into mission_daily(mission_name, mission_content, mission_experience) values
                                                                                 ('Daily Learning', 'Học một bài học', 20),
                                                                                     ('Daily Practice', 'Luyện tập bằng cách làm ít nhất 5 câu hỏi', 30);

insert into topic(topic_name) values ('Word - Từ vựng'), ('Greeting - Lời Chào'),('Verb - Động từ'), ('Phonetics - Ngữ âm'), ('Tenses - Thì'),
                                     ('Tag question - Câu hỏi đuôi'), ('Prepositions - Giới từ'),
                                     ('Adjectives - Tính từ'), ('Adverbs - Trạng từ'), ('Nouns - Danh từ'),
                                     ('Pronouns - Đại từ'), ('Articles - Mạo từ'), ('Quantifiers - Từ chỉ số lượng'),
                                     ('Comparisons - Câu so sánh') ,('Synonyms - Từ đồng nghĩa'),
                                     ('Antonyms - Từ trái nghĩa'), ('Passive Voice - Câu bị động'),
                                     ('Conditional sentences - Câu điều kiện'), ('Reported speech - Câu tường thuật'),
                                     ('Relative clauses - Mệnh đề quan hệ'), ('Gerund - Danh động từ'), ('Idioms - Thành ngữ'),
                                     ('Proverbs - Tục ngữ');

insert into media (media_id, media_name, media_type_id, url)
value (1, 'Avartar', 1, 'images/avatars/avatar.jpg'),
    (2, 'Deafault for male', 1, 'images/avatars/default-male.jpg'),
    (3, 'Deafault for female', 1, 'images/avatars/default-female.jpg'),
    (4, 'Fashion_Accessories.json', 4, 'topics/vocabulary/Fashion_Accessories.json'),
    (5, 'Fashion_Accessories_1.json', 4, 'topics/vocabulary/Fashion_Accessories_1.json'),
    (6, 'Type_Of_Hats.json', 4, 'topics/vocabulary/Type_Of_Hats.json'),
    (7, 'Cloth_Summary.json', 4, 'topics/vocabulary/Cloth_Summary.json'),
    (8, 'Men_clothes.json', 4, 'topics/vocabulary/Men_clothes.json'),
    (9, 'Woman_clothes.json', 4, 'topics/vocabulary/Woman_clothes.json'),
    (10, 'American_And_British_Words_For_Clothes.json', 4, 'topics/vocabulary/American_And_British_Words_For_Clothes.json'),
    (11, 'Common_Action.json', 4, 'topics/vocabulary/Common_Action.json'),
    (12, 'Common_Action_1.json', 4, 'topics/vocabulary/Common_Action_1.json'),
    (13, 'Common_Action_2.json', 4, 'topics/vocabulary/Common_Action_2.json'),
    (14, 'Family_Tree_Chart.json', 4, 'topics/vocabulary/Family_Tree_Chart.json'),
    (15, 'General_Appearance.json', 4, 'topics/vocabulary/General_Appearance.json'),
    (16, 'Adjectives_for_Describing_Age.json', 4, 'topics/vocabulary/Adjectives_for_Describing_Age.json'),
    (17, 'Adjectives_To_Describe_Build.json', 4, 'topics/vocabulary/Adjectives_To_Describe_Build.json'),
    (18, 'Adjectives_To_Describe_Personality_And_Character.json', 4, 'topics/vocabulary/Adjectives_To_Describe_Personality_And_Character.json'),
    (19, 'Formal_Greetings.json', 4, 'topics/greeting/Formal_Greetings.json'),
    (20, 'Informal_Greetings.json', 4, 'topics/greeting/Informal_Greetings.json'),
    (21, 'Definition.json', 4, 'topics/verb/Definition.json'),
    (22, 'Position_Of_Verb.json', 4, 'topics/verb/Position_Of_Verb.json');

insert into user (username, password, email, date_of_birth, full_name, role_id, avatar, streak, experience)
value ('admin', '$2a$12$pF29DXtRmQEOsykpT6s2luBJkEqsyBtdJSXczwkvPGeWuc1/vE/su', null, now(), 'admin', 1, 1, 0, 0),
        ('huuluc10', '$2a$10$kM9U4SjW1bkX9AwC42P2NewpNdeXO.p3ydeHaf4CmUk1OqNfYE8Y6', 'lucnguyenhuu91@gmail.com', '2002-06-10', 'Nguyễn Hữu Lực', 2, 2, 0, 0);

#     insert data into lesson table
insert into lesson(lesson_name, topic_id, content, lesson_experience, level_id)
value ('Fashion Accessories - Phụ kiện', 1, 4, 10, 1),
    ('Fashion Accessories 2 - Phụ kiện', 1, 5, 12, 2),
    ('Type Of Hats - Loại mũ', 1, 6, 10, 1),
    ('Cloth Summary - Tổng kết quần áo', 1, 7, 12, 1),
    ('Men clothes - Quần áo nam', 1, 8, 10, 1),
    ('Woman clothes - Quần áo nữ', 1, 9, 10, 1),
    ('American and british words for clothes - Từ ngữ Mỹ và Anh về quần áo', 1, 10, 20, 2),
    ('Common Action - Hành động thông thường', 1, 11, 10, 1),
    ('Common Action 1 - Hành động thông thường 1', 1, 12, 10, 1),
    ('Common Action 2 - Hành động thông thường 2', 1, 13, 15, 2),
    ('Family Tree Chart - Sơ đồ gia đình', 1, 14, 25, 2),
    ('General Appearance - Ngoại hình', 1, 15, 10, 1),
    ('Adjectives for Describing Age - Tính từ mô tả tuổi tác', 1, 16, 10, 1),
    ('Adjectives To Describe Build - Tính từ mô tả dáng người', 1, 17, 10, 1),
    ('Adjectives To Describe Personality And Character - Tính từ mô tả tính cách và tính tình', 1, 18, 20, 2),
    ('Formal Greetings - Lời chào hỏi trang trọng', 2, 19, 10, 1),
    ('Informal Greetings - Lời chào hỏi không trang trọng', 2, 20, 10, 1),
    ('Definition - Định nghĩa', 3, 21, 10, 1),
    ('Position Of Verb - Vị trí của động từ', 3, 22, 10, 1);

insert into question_type(question_type_name) values ('Multiple choice'), ('Fill in the blank'), ('Match up'),
                                                     ('Sentence transformation'), ('Sentence unscramble'), ('Listening'), ('Speaking');