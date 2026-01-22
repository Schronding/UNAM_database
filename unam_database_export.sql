--
-- PostgreSQL database dump
--

\restrict 6abmYupeOOJrdi8ZNHlxgaRNj179jFgm0kM5hv7MkzlIdfD9mwxuMxsmJTgfWjZ

-- Dumped from database version 15.15 (Debian 15.15-0+deb12u1)
-- Dumped by pg_dump version 15.15 (Debian 15.15-0+deb12u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: bloodtype; Type: TYPE; Schema: public; Owner: schronding
--

CREATE TYPE public.bloodtype AS ENUM (
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-'
);


ALTER TYPE public.bloodtype OWNER TO schronding;

--
-- Name: marital_status; Type: TYPE; Schema: public; Owner: schronding
--

CREATE TYPE public.marital_status AS ENUM (
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Separated'
);


ALTER TYPE public.marital_status OWNER TO schronding;

--
-- Name: maritalstatus; Type: TYPE; Schema: public; Owner: schronding
--

CREATE TYPE public.maritalstatus AS ENUM (
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Separated'
);


ALTER TYPE public.maritalstatus OWNER TO schronding;

--
-- Name: role; Type: TYPE; Schema: public; Owner: schronding
--

CREATE TYPE public.role AS ENUM (
    'administrator',
    'school_services',
    'schronding',
    'technology_coordinator',
    'neurosciences_coordinator'
);


ALTER TYPE public.role OWNER TO schronding;

--
-- Name: status; Type: TYPE; Schema: public; Owner: schronding
--

CREATE TYPE public.status AS ENUM (
    'active',
    'temporal_leave',
    'definite_leave',
    'graduated',
    'titulated'
);


ALTER TYPE public.status OWNER TO schronding;

--
-- Name: titulation; Type: TYPE; Schema: public; Owner: schronding
--

CREATE TYPE public.titulation AS ENUM (
    'support_docency',
    'investigation_activity',
    'amplification_knowledge',
    'postgrade_studies',
    'general_exam',
    'academic_article',
    'titulation_seminar',
    'social_service',
    'thesis',
    'dissertation',
    'academic_level',
    'professional_work'
);


ALTER TYPE public.titulation OWNER TO schronding;

--
-- Name: calculate_total_credits(integer); Type: FUNCTION; Schema: public; Owner: schronding
--

CREATE FUNCTION public.calculate_total_credits(target_student_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    total INTEGER;
BEGIN
    SELECT COALESCE(SUM(s.credits), 0) INTO total
    FROM taken_subjects ts
    JOIN subjects s ON ts.subject_id = s.id
    WHERE ts.student_id = target_student_id
    AND ts.score >= 6;

    RETURN total;
END;
$$;


ALTER FUNCTION public.calculate_total_credits(target_student_id integer) OWNER TO schronding;

--
-- Name: check_attempts_limit(); Type: FUNCTION; Schema: public; Owner: schronding
--

CREATE FUNCTION public.check_attempts_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    passed_already BOOLEAN;
    attempt_count INTEGER;
BEGIN
    SELECT EXISTS (
        SELECT 1 
        FROM taken_subjects 
        WHERE student_id = NEW.student_id 
        AND subject_id = NEW.subject_id 
        AND score >= 6
    ) INTO passed_already;

    IF passed_already THEN
        RAISE EXCEPTION 'Student % has already passed subject %.', NEW.student_id, NEW.subject_id;
    END IF;

    SELECT COUNT(*) INTO attempt_count
    FROM taken_subjects
    WHERE student_id = NEW.student_id
    AND subject_id = NEW.subject_id;

    IF attempt_count >= 2 THEN
        RAISE EXCEPTION 'Student % has already taken subject % twice.', NEW.student_id, NEW.subject_id;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_attempts_limit() OWNER TO schronding;

--
-- Name: check_match_student_career(); Type: FUNCTION; Schema: public; Owner: schronding
--

CREATE FUNCTION public.check_match_student_career() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    student_career INTEGER;
    subject_career INTEGER;
BEGIN
    SELECT career_id INTO student_career
    FROM student_college_info
    WHERE student_id = NEW.student_id; 

    SELECT career INTO subject_career
    FROM subjects
    WHERE subject_career = NEW.subject_id; 

    IF student_career != subject_career THEN
        RAISE EXCEPTION 'There is a mistmatch. The student is in career
        % but the subject is from career %', NEW.student_id, NEW.subject_id;
    END IF; 

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_match_student_career() OWNER TO schronding;

--
-- Name: graduate_student(integer); Type: PROCEDURE; Schema: public; Owner: schronding
--

CREATE PROCEDURE public.graduate_student(IN target_student_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE 
    current_credits INTEGER;
    student_career INTEGER; 
    titulation_status TITULATION; 
BEGIN 
    SELECT credits, career_id, titulation 
    INTO current_credits, student_career, titulation_status
    FROM student_college_info
    WHERE student_id = target_student_id;

    IF current_credits >= 392
    AND titulation_status IS NOT NULL 
    AND student_career = 2 THEN
        UPDATE student_college_info
        SET status = 'graduated' 
        WHERE student_id = target_student_id; 
    END IF; 

    IF current_credits >= 372
    AND titulation_status IS NOT NULL 
    AND student_career = 1 THEN
        UPDATE student_college_info
        SET status = 'graduated' 
        WHERE student_id = target_student_id; 
    END IF; 

    COMMIT; 
END;
$$;


ALTER PROCEDURE public.graduate_student(IN target_student_id integer) OWNER TO schronding;

--
-- Name: update_student_credits(); Type: FUNCTION; Schema: public; Owner: schronding
--

CREATE FUNCTION public.update_student_credits() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_total INTEGER;
BEGIN
    new_total := calculate_total_credits(NEW.student_id);

    UPDATE student_college_info
    SET credits = new_total
    WHERE student_id = NEW.student_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_student_credits() OWNER TO schronding;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: classes; Type: TABLE; Schema: public; Owner: schronding
--

CREATE TABLE public.classes (
    professor_id integer,
    subject_id integer,
    semester integer
);


ALTER TABLE public.classes OWNER TO schronding;

--
-- Name: extraordinary_tests; Type: TABLE; Schema: public; Owner: schronding
--

CREATE TABLE public.extraordinary_tests (
    student_id integer,
    subject_id integer,
    date date,
    score double precision
);


ALTER TABLE public.extraordinary_tests OWNER TO schronding;

--
-- Name: nationalities; Type: TABLE; Schema: public; Owner: schronding
--

CREATE TABLE public.nationalities (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(2)
);


ALTER TABLE public.nationalities OWNER TO schronding;

--
-- Name: nationalities_id_seq; Type: SEQUENCE; Schema: public; Owner: schronding
--

CREATE SEQUENCE public.nationalities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.nationalities_id_seq OWNER TO schronding;

--
-- Name: nationalities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: schronding
--

ALTER SEQUENCE public.nationalities_id_seq OWNED BY public.nationalities.id;


--
-- Name: student_college_info; Type: TABLE; Schema: public; Owner: schronding
--

CREATE TABLE public.student_college_info (
    student_id integer,
    career_id integer,
    code character varying(10),
    beginning date,
    semester integer,
    status public.status,
    regularity boolean,
    ins_email text,
    credits integer,
    titulation public.titulation
);


ALTER TABLE public.student_college_info OWNER TO schronding;

--
-- Name: neuroscience_students; Type: VIEW; Schema: public; Owner: schronding
--

CREATE VIEW public.neuroscience_students AS
 SELECT student_college_info.student_id,
    student_college_info.career_id,
    student_college_info.code,
    student_college_info.beginning,
    student_college_info.semester,
    student_college_info.status,
    student_college_info.regularity,
    student_college_info.ins_email,
    student_college_info.credits,
    student_college_info.titulation
   FROM public.student_college_info
  WHERE (student_college_info.career_id = 2);


ALTER TABLE public.neuroscience_students OWNER TO schronding;

--
-- Name: plan_subjects; Type: TABLE; Schema: public; Owner: schronding
--

CREATE TABLE public.plan_subjects (
    plan_id integer,
    subject_id integer
);


ALTER TABLE public.plan_subjects OWNER TO schronding;

--
-- Name: professors; Type: TABLE; Schema: public; Owner: schronding
--

CREATE TABLE public.professors (
    id integer NOT NULL,
    first_names character varying(100),
    paternal_surname character varying(100),
    maternal_surname character varying(100)
);


ALTER TABLE public.professors OWNER TO schronding;

--
-- Name: professors_id_seq; Type: SEQUENCE; Schema: public; Owner: schronding
--

CREATE SEQUENCE public.professors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.professors_id_seq OWNER TO schronding;

--
-- Name: professors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: schronding
--

ALTER SEQUENCE public.professors_id_seq OWNED BY public.professors.id;


--
-- Name: role_times; Type: TABLE; Schema: public; Owner: schronding
--

CREATE TABLE public.role_times (
    id integer NOT NULL,
    role_name public.role,
    access_time timestamp without time zone
);


ALTER TABLE public.role_times OWNER TO schronding;

--
-- Name: role_times_id_seq; Type: SEQUENCE; Schema: public; Owner: schronding
--

CREATE SEQUENCE public.role_times_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.role_times_id_seq OWNER TO schronding;

--
-- Name: role_times_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: schronding
--

ALTER SEQUENCE public.role_times_id_seq OWNED BY public.role_times.id;


--
-- Name: student_info; Type: TABLE; Schema: public; Owner: schronding
--

CREATE TABLE public.student_info (
    origin character varying(100),
    type_school text,
    average double precision,
    graduation date,
    location text,
    student_id integer
);


ALTER TABLE public.student_info OWNER TO schronding;

--
-- Name: students; Type: TABLE; Schema: public; Owner: schronding
--

CREATE TABLE public.students (
    id integer NOT NULL,
    first_names character varying(100),
    paternal_surname character varying(100),
    maternal_surname character varying(100),
    nationality character varying(2),
    curp character varying(30),
    birth_date date,
    email text,
    telephone character varying(15),
    city character varying(100),
    state character varying(100),
    street character varying(100),
    external_number integer,
    zip_code integer,
    marital_status public.maritalstatus,
    blood_type public.bloodtype,
    nss integer,
    tutor_id integer
);


ALTER TABLE public.students OWNER TO schronding;

--
-- Name: students_id_seq; Type: SEQUENCE; Schema: public; Owner: schronding
--

CREATE SEQUENCE public.students_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.students_id_seq OWNER TO schronding;

--
-- Name: students_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: schronding
--

ALTER SEQUENCE public.students_id_seq OWNED BY public.students.id;


--
-- Name: study_plans; Type: TABLE; Schema: public; Owner: schronding
--

CREATE TABLE public.study_plans (
    id integer NOT NULL,
    name character varying(100),
    code character varying(50),
    duration integer,
    credits integer,
    status boolean NOT NULL
);


ALTER TABLE public.study_plans OWNER TO schronding;

--
-- Name: study_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: schronding
--

CREATE SEQUENCE public.study_plans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.study_plans_id_seq OWNER TO schronding;

--
-- Name: study_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: schronding
--

ALTER SEQUENCE public.study_plans_id_seq OWNED BY public.study_plans.id;


--
-- Name: subjects; Type: TABLE; Schema: public; Owner: schronding
--

CREATE TABLE public.subjects (
    id integer NOT NULL,
    name character varying(100),
    theorical_hours integer,
    practical_hours integer,
    hours integer,
    credits integer,
    area character varying(100),
    career integer,
    semester integer,
    CONSTRAINT hours CHECK (((theorical_hours + practical_hours) <= hours))
);


ALTER TABLE public.subjects OWNER TO schronding;

--
-- Name: subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: schronding
--

CREATE SEQUENCE public.subjects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.subjects_id_seq OWNER TO schronding;

--
-- Name: subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: schronding
--

ALTER SEQUENCE public.subjects_id_seq OWNED BY public.subjects.id;


--
-- Name: taken_subjects; Type: TABLE; Schema: public; Owner: schronding
--

CREATE TABLE public.taken_subjects (
    id integer NOT NULL,
    student_id integer,
    subject_id integer,
    score double precision,
    semester integer,
    acreditation boolean
);


ALTER TABLE public.taken_subjects OWNER TO schronding;

--
-- Name: taken_subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: schronding
--

CREATE SEQUENCE public.taken_subjects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.taken_subjects_id_seq OWNER TO schronding;

--
-- Name: taken_subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: schronding
--

ALTER SEQUENCE public.taken_subjects_id_seq OWNED BY public.taken_subjects.id;


--
-- Name: technology_students; Type: VIEW; Schema: public; Owner: schronding
--

CREATE VIEW public.technology_students AS
 SELECT student_college_info.student_id,
    student_college_info.career_id,
    student_college_info.code,
    student_college_info.beginning,
    student_college_info.semester,
    student_college_info.status,
    student_college_info.regularity,
    student_college_info.ins_email,
    student_college_info.credits,
    student_college_info.titulation
   FROM public.student_college_info
  WHERE (student_college_info.career_id = 1);


ALTER TABLE public.technology_students OWNER TO schronding;

--
-- Name: tutors; Type: TABLE; Schema: public; Owner: schronding
--

CREATE TABLE public.tutors (
    student_id integer,
    professor_id integer
);


ALTER TABLE public.tutors OWNER TO schronding;

--
-- Name: nationalities id; Type: DEFAULT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.nationalities ALTER COLUMN id SET DEFAULT nextval('public.nationalities_id_seq'::regclass);


--
-- Name: professors id; Type: DEFAULT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.professors ALTER COLUMN id SET DEFAULT nextval('public.professors_id_seq'::regclass);


--
-- Name: role_times id; Type: DEFAULT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.role_times ALTER COLUMN id SET DEFAULT nextval('public.role_times_id_seq'::regclass);


--
-- Name: students id; Type: DEFAULT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.students ALTER COLUMN id SET DEFAULT nextval('public.students_id_seq'::regclass);


--
-- Name: study_plans id; Type: DEFAULT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.study_plans ALTER COLUMN id SET DEFAULT nextval('public.study_plans_id_seq'::regclass);


--
-- Name: subjects id; Type: DEFAULT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.subjects ALTER COLUMN id SET DEFAULT nextval('public.subjects_id_seq'::regclass);


--
-- Name: taken_subjects id; Type: DEFAULT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.taken_subjects ALTER COLUMN id SET DEFAULT nextval('public.taken_subjects_id_seq'::regclass);


--
-- Data for Name: classes; Type: TABLE DATA; Schema: public; Owner: schronding
--

COPY public.classes (professor_id, subject_id, semester) FROM stdin;
1	1	1
\.


--
-- Data for Name: extraordinary_tests; Type: TABLE DATA; Schema: public; Owner: schronding
--

COPY public.extraordinary_tests (student_id, subject_id, date, score) FROM stdin;
\.


--
-- Data for Name: nationalities; Type: TABLE DATA; Schema: public; Owner: schronding
--

COPY public.nationalities (id, name, code) FROM stdin;
1	Mexico	MX
2	Germany	DE
3	Andorra	AD
4	Argentina	AR
5	Australia	AU
6	Austria	AT
7	Belgium	BE
8	Bolivia	BO
9	Brazil	BR
10	Canada	CA
\.


--
-- Data for Name: plan_subjects; Type: TABLE DATA; Schema: public; Owner: schronding
--

COPY public.plan_subjects (plan_id, subject_id) FROM stdin;
\.


--
-- Data for Name: professors; Type: TABLE DATA; Schema: public; Owner: schronding
--

COPY public.professors (id, first_names, paternal_surname, maternal_surname) FROM stdin;
1	Valentina	Ramirez	Martinez
2	Paola	Martinez	Islas
3	Valentina	Islas	Islas
4	Alicia	Islas	Boneta
5	Mario	Islas	Godinez
6	Paola	Coronel	Martinez
7	Mario	Martinez	Espiritu
8	Jose	Ramirez	Espiritu
9	Yamil	Ramirez	Espiritu
10	Rogelio	Martinez	Boneta
11	Criseida	Ruiz	Aguilar
12	Mario	Santana	Cibrian
\.


--
-- Data for Name: role_times; Type: TABLE DATA; Schema: public; Owner: schronding
--

COPY public.role_times (id, role_name, access_time) FROM stdin;
\.


--
-- Data for Name: student_college_info; Type: TABLE DATA; Schema: public; Owner: schronding
--

COPY public.student_college_info (student_id, career_id, code, beginning, semester, status, regularity, ins_email, credits, titulation) FROM stdin;
2	1	549877429	2020-06-16	1	titulated	t	Paola.549877429@comunidad.unam.mx	0	\N
3	1	295541129	2023-02-12	1	titulated	t	Rogelio.295541129@comunidad.unam.mx	0	\N
4	1	909003799	2024-02-16	1	active	t	Yamil.909003799@comunidad.unam.mx	0	\N
5	1	242534501	2026-04-11	1	temporal_leave	t	Yamil.242534501@comunidad.unam.mx	0	\N
6	1	710986374	2023-06-14	1	graduated	f	Jose.710986374@comunidad.unam.mx	0	\N
7	1	406810243	2024-03-04	1	definite_leave	f	Alicia.406810243@comunidad.unam.mx	0	\N
8	1	989845050	2023-03-23	1	temporal_leave	f	Paola.989845050@comunidad.unam.mx	0	\N
9	1	394651956	2026-03-15	1	active	f	Hector.394651956@comunidad.unam.mx	0	\N
10	1	542770213	2021-05-16	1	temporal_leave	f	Valentina.542770213@comunidad.unam.mx	0	\N
11	2	306621436	2025-03-20	1	titulated	t	Jose.306621436@comunidad.unam.mx	0	\N
12	2	917929574	2023-02-07	1	active	t	Maria.917929574@comunidad.unam.mx	0	\N
13	2	810788032	2025-02-07	1	active	t	Alicia.810788032@comunidad.unam.mx	0	\N
14	2	361991009	2027-12-22	1	titulated	t	Alicia.361991009@comunidad.unam.mx	0	\N
15	2	714812414	2027-03-11	1	graduated	t	Valentina.714812414@comunidad.unam.mx	0	\N
16	2	800507969	2021-08-05	1	active	f	Valentina.800507969@comunidad.unam.mx	0	\N
17	2	428012847	2022-04-07	1	definite_leave	f	Valentina.428012847@comunidad.unam.mx	0	\N
18	2	148744860	2023-12-22	1	temporal_leave	f	Hector.148744860@comunidad.unam.mx	0	\N
19	2	487765446	2026-07-02	1	temporal_leave	f	Hector.487765446@comunidad.unam.mx	0	\N
20	2	525652150	2021-11-10	1	temporal_leave	f	Rogelio.525652150@comunidad.unam.mx	0	\N
1	1	755127935	2025-04-14	1	graduated	t	Valentina.755127935@comunidad.unam.mx	412	thesis
\.


--
-- Data for Name: student_info; Type: TABLE DATA; Schema: public; Owner: schronding
--

COPY public.student_info (origin, type_school, average, graduation, location, student_id) FROM stdin;
\.


--
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: schronding
--

COPY public.students (id, first_names, paternal_surname, maternal_surname, nationality, curp, birth_date, email, telephone, city, state, street, external_number, zip_code, marital_status, blood_type, nss, tutor_id) FROM stdin;
1	Valentina	Islas	Herrera	AR	9LQU2NZREUTZ6SYJCL	2005-04-14	Valentina_Islas_Herrera@gmail.com	8823870962	QRO	QRO	8	348	30414	Separated	AB+	22046	1
2	Paola	Boneta	Islas	CA	EJRO82CSLWJ69KUR5J	2000-06-16	Paola_Boneta_Islas@gmail.com	3525723629	PUE	PL	3	939	55724	Separated	B-	37444	9
3	Rogelio	Islas	Godinez	CA	VFHAVB11R6WILT0ZQK	2003-02-12	Rogelio_Islas_Godinez@gmail.com	3001876198	JAL	JC	2	98	78474	Separated	B-	63815	9
4	Yamil	Coronel	Martinez	AU	NJCHB5EV44L1N36EBU	2004-02-16	Yamil_Coronel_Martinez@gmail.com	5562024758	AG	AS	2	423	33736	Married	O+	69974	10
5	Yamil	Godinez	Espiritu	DE	2RQW959S138L4FC10R	2006-04-11	Yamil_Godinez_Espiritu@gmail.com	9450978705	PUE	PL	4	814	66627	Married	AB-	78266	3
6	Jose	Espiritu	Coronel	CA	5QZVBBKU42XUUGI8ZC	2003-06-14	Jose_Espiritu_Coronel@gmail.com	9070249542	PUE	PL	3	970	50388	Married	AB-	89769	10
7	Alicia	Coronel	Boneta	CA	X4YF7VOT73BHX871I7	2004-03-04	Alicia_Coronel_Boneta@gmail.com	6868718215	PUE	PL	6	324	94316	Separated	O+	46960	8
8	Paola	Islas	Espiritu	BE	7OTDMJAKFHDVBKPTM7	2003-03-23	Paola_Islas_Espiritu@gmail.com	3139222014	JAL	JC	1	424	44886	Divorced	A-	93593	1
9	Hector	Ramirez	Boneta	BO	AKY5674EDPHHAN7E00	2006-03-15	Hector_Ramirez_Boneta@gmail.com	4592680178	AG	AS	3	220	81612	Married	A-	97629	5
10	Valentina	Gomez	Martinez	BO	Q12KVKOA4CDLWYWRQ6	2001-05-16	Valentina_Gomez_Martinez@gmail.com	5386356640	AG	AS	2	11	26596	Separated	AB-	67843	8
11	Jose	Coronel	Martinez	MX	SEGJSCAECAH0IQESMU	2005-03-20	Jose_Coronel_Martinez@gmail.com	3507221064	MEX	CDMX	3	602	27740	Separated	O+	64324	3
12	Maria	Godinez	Islas	AD	417INXLPW591LX9N6T	2003-02-07	Maria_Godinez_Islas@gmail.com	1473120414	QRO	QRO	9	285	50660	Widowed	O+	17164	6
13	Alicia	Ramirez	Espiritu	MX	T9IE2KW4UP18TDSMCA	2005-02-07	Alicia_Ramirez_Espiritu@gmail.com	8323177961	JAL	JC	4	757	48596	Widowed	AB+	75294	1
14	Alicia	Gomez	Herrera	BO	K731W7OOX0UG3I0MFQ	2007-12-22	Alicia_Gomez_Herrera@gmail.com	2929114982	QRO	QRO	2	231	48733	Separated	B-	86915	1
15	Valentina	Boneta	Coronel	BE	WXRYUYU7RBDHF5UD4N	2007-03-11	Valentina_Boneta_Coronel@gmail.com	8606550312	JAL	JC	7	683	36456	Widowed	B+	95154	7
16	Valentina	Ramirez	Martinez	BO	00C0V8A10APTRCJNRM	2001-08-05	Valentina_Ramirez_Martinez@gmail.com	1947416491	JAL	JC	6	548	29064	Single	O+	24226	1
17	Valentina	Martinez	Martinez	MX	RHKECSKT2UMJQJHCCH	2002-04-07	Valentina_Martinez_Martinez@gmail.com	2774993098	JAL	JC	5	433	89311	Divorced	AB+	78088	8
18	Hector	Coronel	Boneta	AT	5P5K7HEIV7VCDNBAJV	2003-12-22	Hector_Coronel_Boneta@gmail.com	8128318244	MEX	CDMX	8	257	73841	Single	O+	26887	1
19	Hector	Herrera	Martinez	AT	48YE0UI2ED9H0RM7GS	2006-07-02	Hector_Herrera_Martinez@gmail.com	3907691031	QRO	QRO	3	788	58109	Single	O+	29237	7
20	Rogelio	Gomez	Boneta	BR	5I5323KN65JWV41AGW	2001-11-10	Rogelio_Gomez_Boneta@gmail.com	6338450395	AG	AS	2	612	67522	Single	A+	85553	10
\.


--
-- Data for Name: study_plans; Type: TABLE DATA; Schema: public; Owner: schronding
--

COPY public.study_plans (id, name, code, duration, credits, status) FROM stdin;
1	undergraduate in technology	126	8	372	t
2	undergraduate in neurosciences	127	8	392	t
\.


--
-- Data for Name: subjects; Type: TABLE DATA; Schema: public; Owner: schronding
--

COPY public.subjects (id, name, theorical_hours, practical_hours, hours, credits, area, career, semester) FROM stdin;
1	Calculo I	80	0	80	10	Matematicas	1	1
2	Algebra Lineal y Geometria Analitica	48	0	48	6	Matematicas	1	1
3	Quimica Inorganica	64	32	96	10	Quimica	1	1
4	Biologia General	64	32	96	10	Biologia	1	2
5	Tecnicas de Aprendizaje y Creatividad	80	0	80	10	Sociales	1	2
6	Calculo II	80	0	80	10	Matematicas	1	2
7	Mecanica Clasica	64	32	96	10	Fisica	1	3
8	Quimica Organica	64	32	96	10	Quimica	1	3
9	Ecuaciones Diferenciales I	64	0	64	8	Matematicas	1	3
10	Computacion I	48	32	80	8	Computo	1	4
11	Matematicas I	96	0	96	12	Ciencias Basicas	2	1
12	Fisicoquimica	96	0	96	12	Ciencias Basicas	2	1
13	Biologia Celular	64	0	64	8	Ciencias Basicas	2	1
14	Morfofisiologia de los Sistemas	96	0	96	12	Neurobiologico	2	2
15	Neuroanatomia Funcional	64	0	64	8	Neurobiologico	2	2
16	Histologia y Microscopia	0	160	160	10	Ciencias Basicas	2	2
17	Biofisica	64	0	64	8	Ciencias Basicas	2	3
18	Matematicas II	64	0	64	8	Ciencias Basicas	2	3
19	Bioquimica	96	0	96	12	Ciencias Basicas	2	3
20	Introduccion a las Neurociencias	96	0	96	12	Neurobiologico	2	3
21	Thesis Project	300	0	300	400	Investigation	1	9
\.


--
-- Data for Name: taken_subjects; Type: TABLE DATA; Schema: public; Owner: schronding
--

COPY public.taken_subjects (id, student_id, subject_id, score, semester, acreditation) FROM stdin;
1	1	20	10	1	t
3	1	21	10	9	t
\.


--
-- Data for Name: tutors; Type: TABLE DATA; Schema: public; Owner: schronding
--

COPY public.tutors (student_id, professor_id) FROM stdin;
\.


--
-- Name: nationalities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: schronding
--

SELECT pg_catalog.setval('public.nationalities_id_seq', 10, true);


--
-- Name: professors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: schronding
--

SELECT pg_catalog.setval('public.professors_id_seq', 12, true);


--
-- Name: role_times_id_seq; Type: SEQUENCE SET; Schema: public; Owner: schronding
--

SELECT pg_catalog.setval('public.role_times_id_seq', 1, true);


--
-- Name: students_id_seq; Type: SEQUENCE SET; Schema: public; Owner: schronding
--

SELECT pg_catalog.setval('public.students_id_seq', 20, true);


--
-- Name: study_plans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: schronding
--

SELECT pg_catalog.setval('public.study_plans_id_seq', 2, true);


--
-- Name: subjects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: schronding
--

SELECT pg_catalog.setval('public.subjects_id_seq', 21, true);


--
-- Name: taken_subjects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: schronding
--

SELECT pg_catalog.setval('public.taken_subjects_id_seq', 3, true);


--
-- Name: nationalities nationalities_code_key; Type: CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.nationalities
    ADD CONSTRAINT nationalities_code_key UNIQUE (code);


--
-- Name: nationalities nationalities_pkey; Type: CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.nationalities
    ADD CONSTRAINT nationalities_pkey PRIMARY KEY (id);


--
-- Name: professors professors_pkey; Type: CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.professors
    ADD CONSTRAINT professors_pkey PRIMARY KEY (id);


--
-- Name: role_times role_times_pkey; Type: CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.role_times
    ADD CONSTRAINT role_times_pkey PRIMARY KEY (id);


--
-- Name: student_college_info student_college_info_ins_email_key; Type: CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.student_college_info
    ADD CONSTRAINT student_college_info_ins_email_key UNIQUE (ins_email);


--
-- Name: student_info student_info_student_id_key; Type: CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.student_info
    ADD CONSTRAINT student_info_student_id_key UNIQUE (student_id);


--
-- Name: students students_email_key; Type: CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_email_key UNIQUE (email);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);


--
-- Name: study_plans study_plans_name_key; Type: CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.study_plans
    ADD CONSTRAINT study_plans_name_key UNIQUE (name);


--
-- Name: study_plans study_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.study_plans
    ADD CONSTRAINT study_plans_pkey PRIMARY KEY (id);


--
-- Name: subjects subjects_name_key; Type: CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_name_key UNIQUE (name);


--
-- Name: subjects subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_pkey PRIMARY KEY (id);


--
-- Name: taken_subjects taken_subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.taken_subjects
    ADD CONSTRAINT taken_subjects_pkey PRIMARY KEY (id);


--
-- Name: taken_subjects trigger_check_attempts; Type: TRIGGER; Schema: public; Owner: schronding
--

CREATE TRIGGER trigger_check_attempts BEFORE INSERT ON public.taken_subjects FOR EACH ROW EXECUTE FUNCTION public.check_attempts_limit();


--
-- Name: taken_subjects trigger_update_credits; Type: TRIGGER; Schema: public; Owner: schronding
--

CREATE TRIGGER trigger_update_credits AFTER INSERT OR DELETE OR UPDATE ON public.taken_subjects FOR EACH ROW EXECUTE FUNCTION public.update_student_credits();


--
-- Name: classes classes_professor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT classes_professor_id_fkey FOREIGN KEY (professor_id) REFERENCES public.professors(id);


--
-- Name: classes classes_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT classes_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id);


--
-- Name: extraordinary_tests extraordinary_tests_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.extraordinary_tests
    ADD CONSTRAINT extraordinary_tests_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: extraordinary_tests extraordinary_tests_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.extraordinary_tests
    ADD CONSTRAINT extraordinary_tests_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id);


--
-- Name: plan_subjects plan_subjects_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.plan_subjects
    ADD CONSTRAINT plan_subjects_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.study_plans(id);


--
-- Name: plan_subjects plan_subjects_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.plan_subjects
    ADD CONSTRAINT plan_subjects_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id);


--
-- Name: student_college_info student_college_info_career_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.student_college_info
    ADD CONSTRAINT student_college_info_career_id_fkey FOREIGN KEY (career_id) REFERENCES public.study_plans(id);


--
-- Name: student_college_info student_college_info_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.student_college_info
    ADD CONSTRAINT student_college_info_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: student_info student_info_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.student_info
    ADD CONSTRAINT student_info_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: subjects subjects_career_fkey; Type: FK CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_career_fkey FOREIGN KEY (career) REFERENCES public.study_plans(id);


--
-- Name: taken_subjects taken_subjects_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.taken_subjects
    ADD CONSTRAINT taken_subjects_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: taken_subjects taken_subjects_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.taken_subjects
    ADD CONSTRAINT taken_subjects_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id);


--
-- Name: tutors tutors_professor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.tutors
    ADD CONSTRAINT tutors_professor_id_fkey FOREIGN KEY (professor_id) REFERENCES public.professors(id);


--
-- Name: tutors tutors_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: schronding
--

ALTER TABLE ONLY public.tutors
    ADD CONSTRAINT tutors_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: TABLE technology_students; Type: ACL; Schema: public; Owner: schronding
--

GRANT SELECT ON TABLE public.technology_students TO technology_coordinator;


--
-- PostgreSQL database dump complete
--

\unrestrict 6abmYupeOOJrdi8ZNHlxgaRNj179jFgm0kM5hv7MkzlIdfD9mwxuMxsmJTgfWjZ

