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
    lesson_name text not null,
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

insert into topic(topic_name) values ('Word - Từ vựng'), ('Greeting - Lời Chào'), ('Verb - Động từ'), ('Phonetics - Ngữ âm'), ('Tenses - Thì'),
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

    # insert lesson data
    # vocabulary topic
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
    # greeting topic
    (19, 'Formal_Greetings.json', 4, 'topics/greeting/Formal_Greetings.json'),
    (20, 'Informal_Greetings.json', 4, 'topics/greeting/Informal_Greetings.json'),
    # verb topic
    (21, 'Definition_Of_Verb.json', 4, 'topics/verb/Definition_Of_Verb.json'),
    (22, 'Position_Of_Verb.json', 4, 'topics/verb/Position_Of_Verb.json'),
    (23, 'Classify_Verbs_According_to_Meaning.json', 4, 'topics/verb/Classify_Verbs_According_to_Meaning.json'),
    # phonetics topic
    (24, 'Ipa_Table.json', 4, 'topics/phonetics/Ipa_Table.json'),
    (25, 'Phonetics_Pronunciation.json', 4, 'topics/phonetics/Phonetics_Pronunciation.json'),
    # tenses topic
    (26, 'Present_Simple.json', 4, 'topics/tenses/Present_Simple.json'),
    (27, 'Present_Continuous.json', 4, 'topics/tenses/Present_Continuous.json'),
    (28, 'Present_Perfect.json', 4, 'topics/tenses/Present_Perfect.json'),
    (29, 'Present_Perfect_Continuous.json', 4, 'topics/tenses/Present_Perfect_Continuous.json'),
    (30, 'Past_Simple.json', 4, 'topics/tenses/Past_Simple.json'),
    (31, 'Past_Continuous.json', 4, 'topics/tenses/Past_Continuous.json'),
    (32, 'Past_Perfect.json', 4, 'topics/tenses/Past_Perfect.json'),
    (33, 'Past_Perfect_Continuous.json', 4, 'topics/tenses/Past_Perfect_Continuous.json'),
    (34, 'Future_Simple.json', 4, 'topics/tenses/Future_Simple.json'),
    (35, 'Future_Continuous.json', 4, 'topics/tenses/Future_Continuous.json'),
    (36, 'Future_Perfect.json', 4, 'topics/tenses/Future_Perfect.json'),
    (37, 'Future_Perfect_Continuous.json', 4, 'topics/tenses/Future_Perfect_Continuous.json'),
    # tag question topic
    (38, 'Tag_Question_Definition.json', 4, 'topics/tag_question/Tag_Question_Definition.json'),
    (39, 'Tag_Question_Structure.json', 4, 'topics/tag_question/Tag_Question_Structure.json'),
    # prepositions topic
    (40, 'Preposition_Concept.json', 4, 'topics/prepositions/Preposition_Concept.json'),
    (41, 'Preposition_Classification.json', 4, 'topics/prepositions/Preposition_Classification.json'),
    (42, 'Preposition_Position.json', 4, 'topics/prepositions/Preposition_Position.json'),
    (43, 'How_To_Use_Prepositions.json', 4, 'topics/prepositions/How_To_Use_Prepositions.json'),
    (44, 'Note_The_Preposition.json', 4, 'topics/prepositions/Note_The_Preposition.json'),
    # adjectives topic
    (45, 'Definition_Of_Adjective.json', 4, 'topics/adjectives/Definition_Of_Adjective.json'),
    (46, 'Position_Of_Adjective.json', 4, 'topics/adjectives/Position_Of_Adjective.json'),
    (47, 'How_To_Use_Adjective.json', 4, 'topics/adjectives/How_To_Use_Adjective.json'),
    # advetbs topic
    (48, 'Definition_Of_Adverb.json', 4, 'topics/adverbs/Definition_Of_Adverb.json'),
    (49, 'Function_Of_Adverb.json', 4, 'topics/adverbs/Function_Of_Adverb.json'),
    (50, 'Position_Of_Adverb.json', 4, 'topics/adverbs/Position_Of_Adverb.json'),
    (51, 'Adverb_Classification.json', 4, 'topics/adverbs/Adverb_Classification.json'),
    # nouns topic
    (52, 'Definition_of_nouns.json', 4, 'topics/nouns/Definition_of_nouns.json'),
    (53, 'Function_of_nouns.json', 4, 'topics/nouns/Function_of_nouns.json'),
    (54, 'Nouns_classification.json', 4, 'topics/nouns/Nouns_classification.json'),
    (55, 'Position_of_nouns.json', 4, 'topics/nouns/Position_of_nouns.json'),
    # pronouns topic
    (56, 'Definition_Of_Pronouns.json', 4, 'topics/pronouns/Definition_Of_Pronouns.json'),
    (57, 'Pronoun_Classification.json', 4, 'topics/pronouns/Pronoun_Classification.json'),
    # articles topic
    (58, 'Definition_Of_Article.json', 4, 'topics/articles/Definition_Of_Articles.json'),
    (59, 'How_To_Use_Articles.json', 4, 'topics/articles/How_To_Use_Articles.json'),
    # quantifiers topic
    (60, 'Definition_Of_Quantifiers.json', 4, 'topics/quantifiers/Definition_Of_Quantifiers.json'),
    (61, 'How_To_Use_Quantifiers.json', 4, 'topics/quantifiers/How_To_Use_Quantifiers.json'),
    # comparisons topic
    (62, 'Comparative.json', 4, 'topics/comparisons/Comparative.json'),
    (63, 'Equal_comparison.json', 4, 'topics/comparisons/Equal_comparison.json'),
    (64, 'Superlative.json', 4, 'topics/comparisons/Superlative.json'),
    (65, 'Double_Comparison.json', 4, 'topics/comparisons/Double_Comparison.json'),
    (66, 'Types_of_Adjectives_and_Adverbs.json', 4, 'topics/comparisons/Types_of_Adjectives_and_Adverbs.json'),
    # synonyms topic
    (67, 'Synonyms.json', 4, 'topics/synonyms/Synonyms.json'),
    (68, 'Synonym_Pairs.json', 4, 'topics/synonyms/Synonym_Pairs.json'),
    # antonyms topic
    (69, 'Antonyms.json', 4, 'topics/antonyms/Antonyms.json'),
    (70, 'Pair_Of_Adjectives_And_Pairs_Of_Antonyms.json', 4, 'topics/antonyms/Pair_Of_Adjectives_And_Pairs_Of_Antonyms.json'),
    (71, 'Pair_Of_Opposite_Nouns.json', 4, 'topics/antonyms/Pair_Of_Opposite_Nouns.json'),
    (72, 'Pair_Of_Opposite_Verbs.json', 4, 'topics/antonyms/Pair_Of_Opposite_Verbs.json'),
    (73, 'Antonym_Pairs_Of_Prepositions.json', 4, 'topics/antonyms/Antonym_Pairs_Of_Prepositions.json'),
    # passive voice topic
    (74, 'Definition_Of_Passive_Voice.json', 4, 'topics/passive_voice/Definition_Of_Passive_Voice.json'),
    (75, 'Passive_Sentence_Structure.json', 4, 'topics/passive_voice/Passive_Sentence_Structure.json'),
    (76, 'Special_Form_Of_Passive_Sentence.json', 4, 'topics/passive_voice/Special_Form_Of_Passive_Sentence.json'),
    (77, 'Notes_When_Converting_From_Active_Sentences_To_Passive_Sentences.json', 4, 'topics/passive_voice/Notes_When_Converting_From_Active_Sentences_To_Passive_Sentences.json'),
    # conditional sentences topic
    (78, 'Definition_Of_Conditional_Sentences.json', 4, 'topics/conditional_sentences/Definition_Of_Conditional_Sentences.json'),
    (79, 'Zero_Conditional.json', 4, 'topics/conditional_sentences/Zero_Conditional.json'),
    (80, 'Conditional_Sentences_Type_1.json', 4, 'topics/conditional_sentences/Conditional_Sentences_Type_1.json'),
    (81, 'Conditional_Sentences_Type_2.json', 4, 'topics/conditional_sentences/Conditional_Sentences_Type_2.json'),
    (82, 'Conditional_Sentences_Type_3.json', 4, 'topics/conditional_sentences/Conditional_Sentences_Type_3.json'),
    (83, 'Mixed_Conditional_Sentences.json', 4, 'topics/conditional_sentences/Mixed_Conditional_Sentences.json'),
    # reported speech topic
    (84, 'Definition_Of_Reported_Speech.json', 4, 'topics/reported_speech/Definition_Of_Reported_Speech.json'),
    (85, 'Reported_Speech_Structure.json', 4, 'topics/reported_speech/Reported_Speech_Structure.json'),
    (86, 'Reported_Speech_With_Questions.json', 4, 'topics/reported_speech/Reported_Speech_With_Questions.json'),
    (87, 'How_To_Change-From_Direct_Speech_To_Reported_Speech.json', 4, 'topics/reported_speech/How_To_Change-From_Direct_Speech_To_Reported_Speech.json'),
    (88, 'Some_Special_Reported_Sentences.json', 4, 'topics/reported_speech/Some_Special_Reported_Sentences.json'),
    (89, 'Note_When_Converting_From_Direct_Speech_To_Reported_Speech.json', 4, 'topics/reported_speech/Note_When_Converting_From_Direct_Speech_To_Reported_Speech.json'),
    # relative clauses topic
    (90, 'Definition_Of_Relative_Clauses.json', 4, 'topics/relative_clauses/Definition_Of_Relative_Clauses.json'),
    (91, 'Types_Of_Words_Used_In_Relative_Clauses.json', 4, 'topics/relative_clauses/Types_Of_Words_Used_In_Relative_Clauses.json'),
    (92, 'Types_Of_Relative_Clauses.json', 4, 'topics/relative_clauses/Types_Of_Relative_Clauses.json'),
    (93, 'How_To_Shorten_Relative_Clauses.json', 4, 'topics/relative_clauses/How_To_Shorten_Relative_Clauses.json'),
    # gerund topic
    (94, 'Definition_Of_Gerund.json', 4, 'topics/gerund/Definition_Of_Gerund.json'),
    (95, 'Perfect_Gerund.json', 4, 'topics/gerund/Perfect_Gerund.json'),
    (96, 'Cases_That_Go_With_Gerunds.json', 4, 'topics/gerund/Cases_That_Go_With_Gerunds.json'),
    # idioms topic
    (97, 'Definition_Of_Idioms.json', 4, 'topics/idioms/Definition_Of_Idioms.json'),
    (98, 'Examples_Idioms.json', 4, 'topics/idioms/Examples_Idioms.json'),
    # proverbs topic
    (99, 'Definition_Of_Proverbs.json', 4, 'topics/proverbs/Definition_Of_Proverbs.json'),
    (100, 'Example_Proverb.json', 4, 'topics/proverbs/Example_Proverb.json'),

    # insert data question
    # insert vocabulary multiple choice question
    (101, 'vo_multichoice_fashion_accessories_1.json',4, 'questions/accessories/vo_multichoice_fashion_accessories_1.json'),
    (102, 'vo_multichoice_fashion_accessories_2.json',4, 'questions/accessories/vo_multichoice_fashion_accessories_2.json'),
    (103, 'vo_multichoice_fashion_accessories_3.json', 4, 'questions/accessories/vo_multichoice_fashion_accessories_3.json'),
    (104, 'vo_multichoice_fashion_accessories_4.json', 4, 'questions/accessories/vo_multichoice_fashion_accessories_4.json'),
    (105, 'vo_multichoice_fashion_accessories_5.json', 4, 'questions/accessories/vo_multichoice_fashion_accessories_5.json'),
    (106, 'vo_multichoice_fashion_accessories_6.json', 4, 'questions/accessories/vo_multichoice_fashion_accessories_6.json'),
    (107, 'vo_multichoice_fashion_accessories_7.json', 4, 'questions/accessories/vo_multichoice_fashion_accessories_7.json'),
    (108, 'vo_multichoice_fashion_accessories_8.json', 4, 'questions/accessories/vo_multichoice_fashion_accessories_8.json'),
    (109, 'vo_multichoice_fashion_accessories_9.json', 4, 'questions/accessories/vo_multichoice_fashion_accessories_9.json'),
    (110, 'vo_multichoice_fashion_accessories_10.json', 4, 'questions/accessories/vo_multichoice_fashion_accessories_10.json'),

    # insert tenses present simple multiple choice question
    (111, 'tense_multichoice_present_simple_1.json', 4, 'questions/tenses/tense_multichoice_present_simple_1.json'),
    (112, 'tense_multichoice_present_simple_2.json', 4, 'questions/tenses/tense_multichoice_present_simple_2.json'),
    (113, 'tense_multichoice_present_simple_3.json', 4, 'questions/tenses/tense_multichoice_present_simple_3.json'),
    (114, 'tense_multichoice_present_simple_4.json', 4, 'questions/tenses/tense_multichoice_present_simple_4.json'),
    (115, 'tense_multichoice_present_simple_5.json', 4, 'questions/tenses/tense_multichoice_present_simple_5.json'),
    (116, 'tense_multichoice_present_simple_6.json', 4, 'questions/tenses/tense_multichoice_present_simple_6.json'),
    (117, 'tense_multichoice_present_simple_7.json', 4, 'questions/tenses/tense_multichoice_present_simple_7.json'),
    (118, 'tense_multichoice_present_simple_8.json', 4, 'questions/tenses/tense_multichoice_present_simple_8.json'),
    (119, 'tense_multichoice_present_simple_9.json', 4, 'questions/tenses/tense_multichoice_present_simple_9.json'),
    (120, 'tense_multichoice_present_simple_10.json', 4, 'questions/tenses/tense_multichoice_present_simple_10.json'),
    (121, 'tense_multichoice_present_simple_11.json', 4, 'questions/tenses/tense_multichoice_present_simple_11.json'),
    (122, 'tense_multichoice_present_simple_12.json', 4, 'questions/tenses/tense_multichoice_present_simple_12.json'),
    (123, 'tense_multichoice_present_simple_13.json', 4, 'questions/tenses/tense_multichoice_present_simple_13.json'),
    (124, 'tense_multichoice_present_simple_14.json', 4, 'questions/tenses/tense_multichoice_present_simple_14.json'),
    (125, 'tense_multichoice_present_simple_15.json', 4, 'questions/tenses/tense_multichoice_present_simple_15.json'),
    (126, 'tense_multichoice_present_simple_16.json', 4, 'questions/tenses/tense_multichoice_present_simple_16.json'),
    (127, 'tense_multichoice_present_simple_17.json', 4, 'questions/tenses/tense_multichoice_present_simple_17.json'),
    (128, 'tense_multichoice_present_simple_18.json', 4, 'questions/tenses/tense_multichoice_present_simple_18.json'),
    (129, 'tense_multichoice_present_simple_19.json', 4, 'questions/tenses/tense_multichoice_present_simple_19.json'),
    (130, 'tense_multichoice_present_simple_20.json', 4, 'questions/tenses/tense_multichoice_present_simple_20.json'),

    # insert tenses present simple fill question
    (131, 'tense_fill_present_simple_1.json', 4, 'questions/tenses/tense_fill_present_simple_1.json'),
    (132, 'tense_fill_present_simple_2.json', 4, 'questions/tenses/tense_fill_present_simple_2.json'),
    (133, 'tense_fill_present_simple_3.json', 4, 'questions/tenses/tense_fill_present_simple_3.json'),
    (134, 'tense_fill_present_simple_4.json', 4, 'questions/tenses/tense_fill_present_simple_4.json'),
    (135, 'tense_fill_present_simple_5.json', 4, 'questions/tenses/tense_fill_present_simple_5.json'),
    (136, 'tense_fill_present_simple_6.json', 4, 'questions/tenses/tense_fill_present_simple_6.json'),
    (137, 'tense_fill_present_simple_7.json', 4, 'questions/tenses/tense_fill_present_simple_7.json'),
    (138, 'tense_fill_present_simple_8.json', 4, 'questions/tenses/tense_fill_present_simple_8.json'),
    (139, 'tense_fill_present_simple_9.json', 4, 'questions/tenses/tense_fill_present_simple_9.json'),
    (140, 'tense_fill_present_simple_10.json', 4, 'questions/tenses/tense_fill_present_simple_10.json'),
    (141, 'tense_fill_present_simple_11.json', 4, 'questions/tenses/tense_fill_present_simple_11.json'),
    (142, 'tense_fill_present_simple_12.json', 4, 'questions/tenses/tense_fill_present_simple_12.json'),
    (143, 'tense_fill_present_simple_13.json', 4, 'questions/tenses/tense_fill_present_simple_13.json'),
    (144, 'tense_fill_present_simple_14.json', 4, 'questions/tenses/tense_fill_present_simple_14.json'),
    (145, 'tense_fill_present_simple_15.json', 4, 'questions/tenses/tense_fill_present_simple_15.json'),
    (146, 'tense_sentence_um_present_simple_1.json', 4, 'questions/tenses/tense_sentence_um_present_simple_1.json'),
    (147, 'tense_sentence_um_present_simple_2.json', 4, 'questions/tenses/tense_sentence_um_present_simple_2.json'),
    (148, 'tense_sentence_um_present_simple_3.json', 4, 'questions/tenses/tense_sentence_um_present_simple_3.json'),
    (149, 'tense_sentence_um_present_simple_4.json', 4, 'questions/tenses/tense_sentence_um_present_simple_4.json'),
    (150, 'tense_sentence_um_present_simple_5.json', 4, 'questions/tenses/tense_sentence_um_present_simple_5.json'),
    (151, 'tenses_sentence_tran_present_simple_1.json', 4, 'questions/tenses/tenses_sentence_tran_present_simple_1.json'),
    (152, 'tenses_sentence_tran_present_simple_2.json', 4, 'questions/tenses/tenses_sentence_tran_present_simple_2.json'),
    (153, 'tenses_sentence_tran_present_simple_3.json', 4, 'questions/tenses/tenses_sentence_tran_present_simple_3.json'),
    (154, 'tenses_sentence_tran_present_simple_4.json', 4, 'questions/tenses/tenses_sentence_tran_present_simple_4.json'),
    (155, 'tenses_sentence_tran_present_simple_5.json', 4, 'questions/tenses/tenses_sentence_tran_present_simple_5.json'),

    # insert fashion accessories listening question
    (156, 'vo_lis_fashion_accessories_1.json', 4, 'questions/accessories/vo_lis_fashion_accessories_1.json'),
    (157, 'vo_lis_fashion_accessories_2.json', 4, 'questions/accessories/vo_lis_fashion_accessories_2.json'),
    (158, 'vo_lis_fashion_accessories_3.json', 4, 'questions/accessories/vo_lis_fashion_accessories_3.json'),
    (159, 'vo_lis_fashion_accessories_4.json', 4, 'questions/accessories/vo_lis_fashion_accessories_4.json'),
    (160, 'vo_lis_fashion_accessories_5.json', 4, 'questions/accessories/vo_lis_fashion_accessories_5.json'),
    (161, 'vo_lis_fashion_accessories_6.json', 4, 'questions/accessories/vo_lis_fashion_accessories_6.json'),
    (162, 'vo_lis_fashion_accessories_7.json', 4, 'questions/accessories/vo_lis_fashion_accessories_7.json'),
    (163, 'vo_lis_fashion_accessories_8.json', 4, 'questions/accessories/vo_lis_fashion_accessories_8.json'),
    (164, 'vo_lis_fashion_accessories_9.json', 4, 'questions/accessories/vo_lis_fashion_accessories_9.json'),
    (165, 'vo_lis_fashion_accessories_10.json', 4, 'questions/accessories/vo_lis_fashion_accessories_10.json'),

    # insert fashion accessories speaking question
    (166, 'vo_speak_fashion_accessories_1.json', 4, 'questions/accessories/vo_speak_fashion_accessories_1.json'),
    (167, 'vo_speak_fashion_accessories_2.json', 4, 'questions/accessories/vo_speak_fashion_accessories_2.json'),
    (168, 'vo_speak_fashion_accessories_3.json', 4, 'questions/accessories/vo_speak_fashion_accessories_3.json'),
    (169, 'vo_speak_fashion_accessories_4.json', 4, 'questions/accessories/vo_speak_fashion_accessories_4.json'),
    (170, 'vo_speak_fashion_accessories_5.json', 4, 'questions/accessories/vo_speak_fashion_accessories_5.json'),
    (171, 'vo_speak_fashion_accessories_6.json', 4, 'questions/accessories/vo_speak_fashion_accessories_6.json'),
    (172, 'vo_speak_fashion_accessories_7.json', 4, 'questions/accessories/vo_speak_fashion_accessories_7.json'),
    (173, 'vo_speak_fashion_accessories_8.json', 4, 'questions/accessories/vo_speak_fashion_accessories_8.json'),
    (174, 'vo_speak_fashion_accessories_9.json', 4, 'questions/accessories/vo_speak_fashion_accessories_9.json'),
    (175, 'vo_speak_fashion_accessories_10.json', 4, 'questions/accessories/vo_speak_fashion_accessories_10.json'),
    (176, 'vo_speak_fashion_accessories_11.json', 4, 'questions/accessories/vo_speak_fashion_accessories_11.json'),
    (177, 'vo_speak_fashion_accessories_12.json', 4, 'questions/accessories/vo_speak_fashion_accessories_12.json');


insert into user (username, password, email, date_of_birth, full_name, role_id, avatar, streak, experience)
value ('admin', '$2a$12$pF29DXtRmQEOsykpT6s2luBJkEqsyBtdJSXczwkvPGeWuc1/vE/su', null, now(), 'admin', 1, 1, 0, 0),
        ('huuluc10', '$2a$10$kM9U4SjW1bkX9AwC42P2NewpNdeXO.p3ydeHaf4CmUk1OqNfYE8Y6', 'lucnguyenhuu91@gmail.com', '2002-06-10', 'Nguyễn Hữu Lực', 2, 2, 0, 0);

#     insert data into lesson table
insert into lesson(lesson_name, topic_id, content, lesson_experience, level_id)
value ('Fashion Accessories - Phụ kiện', 1, 4, 10, 1),
    ('Fashion Accessories 2 - Phụ kiện', 1, 5, 12, 2),
    ('Type Of Hats - Loại mũ', 1, 6, 10, 1),
    ('Cloth Summary - Tổng kết quần áo', 1, 7, 12, 2),
    ('Men clothes - Quần áo nam', 1, 8, 10, 1),
    ('Woman clothes - Quần áo nữ', 1, 9, 10, 1),
    ('American and british words for clothes - Từ ngữ Mỹ và Anh về quần áo', 1, 10, 20, 2),
    ('Common Action - Hành động thông thường', 1, 11, 10, 1),
    ('Common Action 1 - Hành động thông thường 1', 1, 12, 10, 1),
    ('Common Action 2 - Hành động thông thường 2', 1, 13, 15, 2),
    ('Family Tree Chart - Sơ đồ gia đình', 1, 14, 25, 3),
    ('General Appearance - Ngoại hình', 1, 15, 10, 1),
    ('Adjectives for Describing Age - Tính từ mô tả tuổi tác', 1, 16, 10, 1),
    ('Adjectives To Describe Build - Tính từ mô tả dáng người', 1, 17, 10, 1),
    ('Adjectives To Describe Personality And Character - Tính từ mô tả tính cách và tính tình', 1, 18, 20, 2),
    ('Formal Greetings - Lời chào hỏi trang trọng', 2, 19, 10, 1),
    ('Informal Greetings - Lời chào hỏi không trang trọng', 2, 20, 10, 1),
    ('Definition - Định nghĩa', 3, 21, 10, 1),
    ('Position Of Verb - Vị trí của động từ', 3, 22, 10, 3),
    ('Classify Verbs According to Meaning - Phân loại động từ theo nghĩa', 3, 23, 10, 1),
    ('IPA Table - Bảng phiên âm quốc tế', 4, 24, 14, 2),
    ('Phonetics Pronunciation - Phát âm ngữ âm', 4, 25, 25, 3),
    ('Present Simple - Hiện tại đơn', 5, 26, 10, 1),
    ('Present Continuous - Hiện tại tiếp diễn', 5, 27, 12, 1),
    ('Present Perfect - Hiện tại hoàn thành', 5, 28, 12, 1),
    ('Present Perfect Continuous - Hiện tại hoàn thành tiếp diễn', 5, 29, 14, 2),
    ('Past Simple - Quá khứ đơn', 5, 30, 12, 1),
    ('Past Continuous - Quá khứ tiếp diễn', 5, 31, 12, 1),
    ('Past Perfect - Quá khứ hoàn thành', 5, 32, 14, 2),
    ('Past Perfect Continuous - Quá khứ hoàn thành tiếp diễn', 5, 33, 16, 2),
    ('Future Simple - Tương lai đơn', 5, 34, 12, 1),
    ('Future Continuous - Tương lai tiếp diễn', 5, 35, 12, 1),
    ('Future Perfect - Tương lai hoàn thành', 5, 36, 14, 1),
    ('Future Perfect Continuous - Tương lai hoàn thành tiếp diễn', 5, 37, 16, 2),
    ('Tag Question - Câu hỏi đuôi', 6, 38, 10, 1),
    ('Tag Question Structure - Cấu trúc câu hỏi đuôi', 6, 39, 12, 1),
    ('Prepositions - Giới từ', 7, 40, 10, 1),
    ('Preposition Classification - Phân loại giới từ', 7, 41, 22, 3),
    ('Preposition Position - Vị trí của giới từ', 7, 42, 10, 1),
    ('How To Use Prepositions - Cách sử dụng giới từ', 7, 43, 15, 2),
    ('Note The Preposition - Lưu ý về giới từ', 7, 44, 15, 2),
    ('Definition Of Adjective - Định nghĩa tính từ', 8, 45, 10, 1),
    ('Position Of Adjective - Vị trí của tính từ', 8, 46, 10, 1),
    ('How To Use Adjective - Cách sử dụng tính từ', 8, 47, 15, 2),
    ('Definition Of Adverb - Định nghĩa trạng từ', 9, 48, 8, 1),
    ('Function Of Adverb - Chức năng của trạng từ', 9, 49, 10, 1),
    ('Position Of Adverb - Vị trí của trạng từ', 9, 50, 10, 1),
    ('Adverb Classification - Phân loại trạng từ', 9, 51, 15, 2),
    ('Definition of nouns - Định nghĩa danh từ', 10, 52, 10, 1),
    ('Function of nouns - Chức năng của danh từ', 10, 53, 12, 1),
    ('Nouns classification - Phân loại danh từ', 10, 54, 14, 1),
    ('Position of nouns - Vị trí của danh từ', 10, 55, 12, 1),
    ('Definition Of Pronouns - Định nghĩa đại từ', 11, 56, 8, 1),
    ('Pronoun_Classification - Phân loại đại từ', 11, 57, 15, 2),
    ('Definition Of Article - Định nghĩa mạo từ', 12, 58, 12, 1),
    ('How To Use Articles - Cách sử dụng mạo từ', 12, 59, 15, 2),
    ('Definition Of Quantifiers - Định nghĩa từ chỉ số lượng', 13, 60, 8, 1),
    ('How To Use Quantifiers - Cách sử dụng từ chỉ số lượng', 13, 61, 14, 2),
    ('Comparative - So sánh hơn', 14, 62, 15, 2),
    ('Equal_comparison - So sánh bằng', 14, 63, 12, 1),
    ('Superlative - So sánh nhất', 14, 64, 15, 2),
    ('Double_Comparison - So sánh kép', 14, 65, 16, 2),
    ('Types of Adjectives and Adverbs - Các loại tính từ và trạng từ', 14, 66, 10, 1),
    ('Synonyms - Từ đồng nghĩa', 15, 67, 12, 1),
    ('Synonym_Pairs - Cặp từ đồng nghĩa', 15, 68, 12, 1),
    ('Antonyms - Từ trái nghĩa', 16, 69, 12, 1),
    ('Pair Of Adjectives And Pairs Of Antonyms - Cặp từ tính từ và cặp từ trái nghĩa', 16, 70, 10, 1),
    ('Pair Of Opposite Nouns - Cặp từ danh từ trái nghĩa', 16, 71, 10, 1),
    ('Pair Of Opposite Verbs - Cặp từ động từ trái nghĩa', 16, 72, 10, 1),
    ('Antonym_Pairs_Of_Prepositions - Cặp từ giới từ trái nghĩa', 16, 73, 10, 1),
    ('Definition Of Passive Voice - Định nghĩa giọng bị', 17, 74, 12, 1),
    ('Passive Sentence Structure - Cấu trúc câu giọng bị', 17, 75, 14, 2),
    ('Special Form Of Passive Sentence - Dạng đặc biệt của câu giọng bị', 17, 76, 15, 2),
    ('Notes When Converting From Active Sentences To Passive Sentences - Lưu ý khi chuyển từ câu chủ động sang câu bị động', 17, 77, 14, 1),
    ('Definition Of Conditional Sentences - Định nghĩa câu điều kiện', 18, 78, 10, 1),
    ('Zero Conditional - Câu điều kiện loại 0', 18, 79, 10, 1),
    ('Conditional Sentences Type 1 - Câu điều kiện loại 1', 18, 80, 10, 1),
    ('Conditional Sentences Type 2 - Câu điều kiện loại 2', 18, 81, 10, 1),
    ('Conditional Sentences Type 3 - Câu điều kiện loại 3', 18, 82, 10, 1),
    ('Mixed Conditional Sentences - Câu điều kiện hỗn hợp', 18, 83, 15, 2),
    ('Definition Of Reported Speech - Định nghĩa câu nói gián tiếp', 19, 84, 8, 1),
    ('Reported Speech Structure - Cấu trúc câu nói gián tiếp', 19, 85, 14, 1),
    ('Reported Speech With Questions - Câu nói gián tiếp với câu hỏi', 19, 86, 15, 2),
    ('How To Change-From Direct Speech To Reported Speech - Cách chuyển từ câu trực tiếp sang câu gián tiếp', 19, 87, 20, 1),
    ('Some Special Reported Sentences - Một số câu nói gián tiếp đặc biệt', 19, 88, 10, 1),
    ('Note When Converting From Direct Speech To Reported Speech - Lưu ý khi chuyển từ câu trực tiếp sang câu gián tiếp', 19, 89, 40, 3),
    ('Definition Of Relative Clauses - Định nghĩa mệnh đề quan hệ', 20, 90, 12, 1),
    ('Types Of Words Used In Relative Clauses - Các loại từ được sử dụng trong mệnh đề quan hệ', 20, 91, 15, 2),
    ('Types Of Relative Clauses - Các loại mệnh đề quan hệ', 20, 92, 10, 1),
    ('How To Shorten Relative Clauses - Cách rút gọn mệnh đề quan hệ', 20, 93, 15, 1),
    ('Definition Of Gerund - Định nghĩa động từ nguyên thể', 21, 94, 10, 1),
    ('Perfect Gerund - Động từ nguyên thể hoàn thành', 21, 95, 10, 1),
    ('Cases That Go With Gerunds - Các trường hợp đi cùng với động từ nguyên thể', 21, 96, 15, 2),
    ('Definition Of Idioms - Định nghĩa thành ngữ', 22, 97, 10, 1),
    ('Examples Idioms - Ví dụ về thành ngữ', 22, 98, 12, 1),
    ('Definition Of Proverbs - Định nghĩa tục ngữ', 23, 99, 10, 1),
    ('Example Proverb - Ví dụ về tục ngữ', 23, 100, 12, 1);

insert into question_type(question_type_name) values ('Multiple choice'), ('Fill in the blank'), ('Sentence transformation'),
                                                      ('Sentence unscramble'), ('Listening'), ('Speaking');

insert into question(question_type_id, lesson_id, answer)
value
    # multiple choice of fashion accessories
    # vacabulary
    (1, 1, 29),
    (1, 1, 30),
    (1, 1, 31),
    (1, 1, 32),
    (1, 1, 33),
    (1, 1, 34),
    (1, 1, 35),
    (1, 1, 36),
    (1, 1, 37),
    (1, 1, 38),
    # listening
    (5, 1, 84),
    (5, 1, 85),
    (5, 1, 86),
    (5, 1, 87),
    (5, 1, 88),
    (5, 1, 89),
    (5, 1, 90),
    (5, 1, 91),
    (5, 1, 92),
    (5, 1, 93),
    # speaking
    (6, 1, 94),
    (6, 1, 95),
    (6, 1, 96),
    (6, 1, 97),
    (6, 1, 98),
    (6, 1, 99),
    (6, 1, 100),
    (6, 1, 101),
    (6, 1, 102),
    (6, 1, 103),
    (6, 1, 104),
    (6, 1, 105),

    # tenses
    # multiple choice
    (1, 21, 39),
    (1, 21, 40),
    (1, 21, 41),
    (1, 21, 42),
    (1, 21, 43),
    (1, 21, 44),
    (1, 21, 45),
    (1, 21, 46),
    (1, 21, 47),
    (1, 21, 48),
    (1, 21, 49),
    (1, 21, 50),
    (1, 21, 51),
    (1, 21, 52),
    (1, 21, 53),
    (1, 21, 54),
    (1, 21, 55),
    (1, 21, 56),
    (1, 21, 57),
    (1, 21, 58),
    # fill in the blank
    (2, 21, 59),
    (2, 21, 60),
    (2, 21, 61),
    (2, 21, 62),
    (2, 21, 63),
    (2, 21, 64),
    (2, 21, 65),
    (2, 21, 66),
    (2, 21, 67),
    (2, 21, 68),
    (2, 21, 69),
    (2, 21, 70),
    (2, 21, 71),
    (2, 21, 72),
    (2, 21, 73),
    # sentence unscramble
    (4, 21, 74),
    (4, 21, 75),
    (4, 21, 76),
    (4, 21, 77),
    (4, 21, 78),
    #sentence transformation
    (3, 21, 79),
    (3, 21, 80),
    (3, 21, 81),
    (3, 21, 82),
    (3, 21, 83);