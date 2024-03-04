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
    media_name varchar(30) not null,
    media_type_id tinyint not null,
    url text default null,
    foreign key(media_type_id) references media_type(media_type_id)
);

create table if not exists user
(
    username varchar(30) primary key,
    full_name varchar(70) not null,
    date_of_birth date not null,
    email varchar(50) null,
    password varchar(100) not null,
    avatar int not null,
    role_id tinyint not null,
    streak int not null,
    experience int not null,
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
    lesson_id tinyint primary key auto_increment,
    lesson_name varchar(30) not null,
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
    lesson_id tinyint not null,
    primary key(username, lesson_id),
    foreign key(username) references user(username),
    foreign key(lesson_id) references lesson(lesson_id)
);

create table if not exists exam
(
    exam_id tinyint primary key auto_increment,
    exam_name varchar(30) not null,
    exam_experience int not null,
    exam_level tinyint not null,
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
    lesson_id tinyint null,
    exam_id tinyint null,
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
    primary key(username, question_id),
    foreign key(username) references user(username),
    foreign key(question_id) references question(question_id)
);

insert into media_type(media_type_name) values ('Image'), ('Audio'), ('Video'), ('Json');

insert into role(name) values ('Admin'), ('User');

insert into level(level_name, experience_threshold) values ('Beginner', 0), ('Elementary', 300), ('Intermediate', 800),
                                                           ('Upper Intermediate', 2000), ('Advanced', 4500);

insert into mission_daily(mission_name, mission_content, mission_experience) values
                                                                                 ('Daily Login', 'Login to the app', 10),
                                                                                 ('Daily Learning', 'Learn a lesson', 20),
                                                                                 ('Daily Practice', 'Practice a lesson', 30);

insert into topic(topic_name) values ('Word - Từ vựng'), ('Phonetics - Ngữ âm'),('Verb - Động từ'),('Tenses - Thì'),
                                     ('Tag question - Câu hỏi đuôi'), ('Prepositions - Giới từ'),
                                     ('Adjectives - Tính từ'), ('Adverbs - Trạng từ'), ('Nouns - Danh từ'),
                                     ('Pronouns - Đại từ'), ('Articles - Mạo từ'), ('Quantifiers - Từ chỉ số lượng'),
                                     ('Comparisons - Câu so sánh') ,('Synonyms - Từ đồng nghĩa'),
                                     ('Antonyms - Từ trái nghĩa'), ('Passive Voice - Câu bị động'),
                                     ('Conditional sentences - Câu điều kiện'), ('Reported speech - Câu tường thuật'),
                                     ('Relative clauses - Mệnh đề quan hệ'), ('Gerund - Danh động từ'), ('Idioms - Thành ngữ'),
                                     ('Proverbs - Tục ngữ');

insert into media (media_id, media_name, media_type_id, url)
value (1, 'Avartar', 1, 'images/avatars/avatar.jpg');

insert into user (username, password, email, date_of_birth, full_name, role_id, avatar, streak, experience)
value ('admin', 'admin', null, now(), 'admin', 1, 1, 0, 0);