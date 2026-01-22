import streamlit as st
import pandas as pd
import os
import psycopg
from dotenv import load_dotenv
import random
import string 
import datetime

# While I got a rudimentary working code using the strings of dates
# it seems that people recommend using the library `datetime`. As 
# I don't see any pip install command I will assume it is built in
# python. 

status_lst = ['active', 'temporal_leave', 'definite_leave', 'graduated', 'titulated']
names_lst = ['Jose', 'Mario', 'Rogelio', 'Yamil', 'Hector', 'Alicia','Paola', 'Valeria', 'Valentina', 'Maria']
surnames_lst = ['Ramirez', 'Martinez', 'Espiritu', 'Gomez', 'Godinez', 'Coronel', 'Herrera', 'Boneta', 'Islas']
nationalities_lst = ['MX', 'DE', 'AD', 'AR', 'AU', 'AT', 'BE', 'BO', 'BR', 'CA']
cities_lst = ['AG', 'JAL', 'MEX', 'PUE', 'QRO'] # The city will be the capital
# # of each of these states
bloodtypes_lst = ['A+','A-', 'B+','B-','O+','O-','AB+','AB-']
maritalstatus_lst = ['Single', 'Married', 'Divorced', 'Widowed','Separated']

load_dotenv()

def conn_to_postgres(query, params = None, fetch = False):
    conn = None

    try:
        conn = psycopg.connect(
            host="localhost",
            dbname="unam_database",
            user="schronding",
            password=os.getenv('PASSWORD'),
            port="5432", 
        ) 

        conn.autocommit = True
        cur = conn.cursor()

        cur.execute(query, params)

        if fetch:
            result = cur.fetchone()[0]
            cur.close()
            conn.close()
            return result
            
        results = cur.fetchall()

        for row in results:
            print(row)

        cur.close()
        return conn
    
    except(Exception, psycopg.DatabaseError) as e:
        print(f"Error: {e}")
        if conn:
            cur.close()
        return None

st_conn = st.connection("schronding", type = "sql")
st.title("UNAM Database")
selected_option = st.sidebar.selectbox("Action", ["a. Students", 
"b. Professors", "c. Regularity", "d. Approved", "e. Remaining", 
"f. Subjects", "4. Insert"])

# a. Consultar la lista de estudiantes inscritos totales y por plan de estudios.
# b. Consultar la lista de profesores.
# c. Consultar la lista de estudiantes regulares e irregulares totales y por plan de estudios.
# d. Consultar la lista de materias que ha aprobado un estudiante.
# e. Consultar la lista de materias que debe un estudiante.
# f. Consultar la lista de materias que ha dado un profesor.

# 4. La página de be tener un formulario para ingresar nuevos alumnos y profesores.

if selected_option == "a. Students":
    st.header("Total inscribed students")
    view_choice = st.segmented_control("Views", 
    ["Administrator", "Technology Coordinator", "Neurosciences Coordinator"])
    
    if view_choice == "Administrator":
        df = st_conn.query("SELECT * FROM student_college_info;", ttl = 0)
        # Here I need to put the same time to live as professors, 
        # because if I do not I will continue to see the cached 
        # version of the query. 
        st.dataframe(df)

    if view_choice == "Technology Coordinator":
        df = st_conn.query("SELECT * FROM technology_students;")
        st.dataframe(df)

    if view_choice == "Neurosciences Coordinator":
        df = st_conn.query("SELECT * FROM neuroscience_students;")
        st.dataframe(df)
    

# Wow, I didn't expect it to be that easy. streamlit built a beautiful
# data frame with just 3 lines of code. I have 19 students though, 
# I need to check that

# I don't know how but I don't have any student in students... and the
# student with what should be id 13 doesn't have one... maybe I should
# include the NOT NULL constraint to students. 

# I will just combine student and student_college_info. I get way
# too confused and it doesn't feel right to have them separated. 
# I honestly don't know what is the convenction on the "sweet spot" 
# on the amount of tables a schema can have. 

# I don't know where to put the views. I thought about creating a login
# system, but for that I would need to change the website quite a bit. 
# I think I should just built some SQL queries to show if each
# role has or not the power to modify the database according to the
# requisites. 

# I cannot see the views when I reference them directly as tables, 
# even though I can see that I created them on the psql terminal. 

# The reason why I couldn't see it was rather dumb: I didn't change
# the name of the variable from selected_option to view_choice

elif selected_option == "b. Professors":
    st.header("All the professors of the ENES")
    all_professors = st_conn.query("SELECT * FROM professors;", ttl=0)
    st.dataframe(all_professors)

elif selected_option == "c. Regularity":
    st.header("Regular and irregular students")
    choices = st.multiselect("Select the options", 
    ["Regulars", "Irregulars", 
    "Bachelor's in Technology", "Bachelor's in Neurosciences"])
    df = st_conn.query(""" 
    SELECT
        s.first_names,
        s.paternal_surname,
        s.maternal_surname,
        sci.regularity,
        sci.semester,
        sci.credits,
        sci.career_id
    FROM students s
    JOIN student_college_info sci
    ON s.id = sci.student_id;
    """)

    has_tech = "Bachelor's in Technology" in choices
    has_neuro = "Bachelor's in Neurosciences" in choices

    if has_tech or has_neuro:
        if has_tech and not has_neuro:
            df = df[df.career_id == 1]
        elif has_neuro and not has_tech:
            df = df[df.career_id == 2]
    # This whole block asks the question "does the user want to check
    # a career?" If not then df never touches this block and simply 
    # continues if the user is interested in regularity

    has_regular = "Regulars" in choices
    has_irregular = "Irregulars" in choices

    if has_regular or has_irregular:
        if has_regular and not has_irregular:
            df = df[df.regularity == True]
        elif has_irregular and not has_regular:
            df = df[df.regularity == False]

    st.dataframe(df)
    # It is so interesting to see that the option will all the filters
    # is equal to the option with none!
    

    # It seems I don't even need to JOIN the tables, I can just 
    # access the attributes I want with the dot notation. 

    # I didn't know but I can filter using pandas. As I already
    # have a dataframe, I can just select the attribute that matches
    # the requirements I want. 

    # It worked! But I do have just 10 students. I will rerun the 
    # creation of data to see if that number changes. 

    # I actually had more regular students, I just needed to scroll
    # down. I still have 0. I reruned the code that created the data
    # now changing the True for the parameter I gave 'isregular' 
    # but the dataframe is still empty. 

    # Multiselect quickly ramps up the amount of options I need. 
    # What I wonder is how I got 10 options? I assumed it would be 
    # 2 ^ 3 (8) or 3 ^ 2 (9), but why 10 though? 

    # I don't understand this error, I don't have students_college_info
    # anywhere on this script nor on main.ipybn. Or at least 
    # Control + f doesn't find them
    #LINE 1: SELECT * FROM students_college_info;
    #                 ^

    # I didn't checked, but st.multiselect returns a list. I need to
    # check what options are available (or put the whole list such as
    # choices == ['attribute1', 'attribute2']). 

    # It doesn't work as I expected. When I put both 'Regulars' and 
    # 'B's in Tec' I can still see students with career_id = 2. 

    # I will rewrite this part with 4 selective filters, checking if
    # each of the conditions is applied. 

elif selected_option == "d. Approved":
    st.header("Approved subjects by each student")

    with st.form("approved_subjects"):
        student_id = st.text_input("Type student ID")
        submited = st.form_submit_button("Look up")

        if submited:
            approved_subjects = st_conn.query(f"""
            SELECT s.name, ts.score, ts.semester
            FROM taken_subjects ts
            JOIN subjects s ON s.id = ts.subject_id
            WHERE ts.student_id = {student_id}
            AND ts.score >= 6;
            """, ttl=0)

            # It seems that the problem is that I declared subjects
            # in the FROM, but I should have actually done it on the
            # JOIN clause. The problem seems to be that I can only
            # work on one relation at a time

            st.dataframe(approved_subjects)

# streamlit.errors.StreamlitAPIException: st.form_submit_button() must be used inside an st.form().
# It seems that putting the submit button immediately below the form
# is not enough, I suppose that the button should be a variable used
# in form

# Indeed it needs to be put there, but not as I thought. To work 
# corretly form, the button and the input text (which I did not put)
# must be inside a with block. 

# I wonder when I should put the diminituve of the table. From the
# code I have seen online, it seems inconsequential. 

elif selected_option == "e. Remaining":
    st.markdown("# Subjects to be accredited")
    with st.form("remaining_subjects_per_student"):
        student_id = st.number_input("Student ID", min_value=1, step=1)
        submitted = st.form_submit_button("Check remaining subjects")
        if submitted:
            career_check = st_conn.query(f""" 
            SELECT career_id
            FROM student_college_info
            WHERE student_id = {student_id};
            """)
            if not career_check.empty:
            # I got the error ValueError: 
            # The truth value of a DataFrame is ambiguous. 
            # Use a.empty, a.bool(), a.item(), a.any() or a.all().
                career_id = career_check.iloc[0]['career_id']
                # iloc is just a way to reference a dataframe as if 
                # it was a list: by making use of its index. 

                all_subjects = st_conn.query(f"""
                SELECT name, credits, semester
                FROM subjects
                WHERE career = {career_id}
                AND id NOT IN (
                    SELECT subject_id
                    FROM taken_subjects
                    WHERE student_id = {student_id}
                    AND score >= 6
                )
                ORDER BY semester ASC;
                """)

                st.dataframe(all_subjects)




# Now that I think about it I could also subtract the passed subjects
# from the total. This is easier at least with the current state of 
# the database. 

# Also, I didn't noticed at first on the API reference of streamlit,
# but there is a 'number_input' method. 

# I also noticed that we have a step argument that allows to specify
# how "big" are the jumps between the data that is inserted. 

# I wanted to use my conn_to_postgres function but the problem is 
# that I have not experimented saving the value to a variable... but I 
# did though, then why my web site become frozen all of a sudden?

# It seems to be an error in step d. It makes sense! I cannot see e 
# as d has not been runned yet. 

elif selected_option == "f. Subjects":
    st.markdown("# Subjects that the professor taught")
    with st.form("professor_subjects_search"):
        professor_id = st.number_input("Type the professor ID", min_value=1, step=1)
        submited = st.form_submit_button("Look up")

        if submited:
            complete_clases = st_conn.query(f"""
            SELECT
                pro.first_names,
                pro.paternal_surname,
                pro.maternal_surname, 
                sub.name,
                cla.semester
            FROM professors pro
            JOIN classes cla ON pro.id = cla.professor_id
            JOIN subjects sub ON sub.id = cla.subject_id 
            WHERE pro.id = {professor_id}; 
            """)

            st.dataframe(complete_clases)

# It seems that the JOIN clauses must come after, and that I need
# a total number of JOIN clauses equal to (number_of_tables - 1) times

# While my logic would tell me that I need to join something before
# taking a group from it, in seems that in postgres it goes in reverse; 
# first are the SELECT clauses, then the JOIN ones. 

# I got an error that wasn't solved by correcting the inconsistent
# uses of pro as p... The problem with the library as that even though
# it helps me hide a lot of the background work, the error messages
# are painfully long and it is difficult for me to pinpoint what
# the real mistake is. 

elif selected_option == "4. Insert":
    st.markdown("# Insert new professors or students")
    option = st.segmented_control("You want to create a...", ["Student", "Professor"])
    if option == "Professor":
        with st.form("insert_new_professor"):
            names = st.text_input("First names", max_chars=100)
            pat_surname = st.text_input("Paternal surname", max_chars=100)
            mat_surname = st.text_input("Maternal surname", max_chars=100)
            submited = st.form_submit_button()
            if submited:
                insert_professor_query = (""" 
                INSERT INTO professors(first_names, paternal_surname, maternal_surname)
                VALUES(%s, %s, %s);
                """)

                professor_values = (names, pat_surname, mat_surname)
                conn_to_postgres(insert_professor_query, professor_values)
                st.success("Professor created succesfully")

                st.rerun()

                # While it says that the professor was created I
                # don't see it in the table of all the professors
                # of the ENES. When I go to the database I
                # have the duplication of the last professor though. 
                # Could it be that it runs the queries just once 
                # and that is the reason why it doesn't change? 
                # This is interesting, when I closed and reopened
                # the streamlit web page the last profesor (Criseida)
                # now appears, but the new I just created doesn't. 
                # I think this could be the exercise where I prove
                # that school_services and the coordinators cannot
                # delete the entry. 

                # I am getting the error
                # postgres=# \c unam_database schronding;
                #  connection to server on socket 
                # "/var/run/postgresql/.s.PGSQL.5432" failed: 
                # FATAL:  Peer authentication failed for user 
                # "schronding" Previous connection kept

                # I think it might be because I am running the web
                # page and this already has the schronding user
                # enabled. 

                # It seems that isn't the reason, as when I stop the
                # web page it doesn't allow me to enter either. 
                # I should be able to enter with the other roles
                # though. 

                # Maybe it is the port. As no role can connect.
                # 
                # I don't know how to delete a tuple. When I typed
                # unam_database=# DELETE * FROM professors
                # unam_database-# WHERE id = 11;
                # ERROR:  syntax error at or near "*"
                # LINE 1: DELETE * FROM professors
                #                ^
                # I was able to enter with a separate role though. 

# I am confused at why I am unable to acess the professors table
# unam_database=> SELECT * FROM students;
# ERROR:  permission denied for table students
# unam_database=> SELECT * FROM professors;
# ERROR:  permission denied for table professors
# unam_database=> SELECT * FROM technology_students 
# unam_database-> ;
# ERROR:  permission denied for view technology_students
# I granted access to the views
# ```SQL
# GRANT SELECT ON professors TO technology_coordinator, neurosciences_coordinator;
# GRANT
# ```
# It seems I have not granted usage nor connection to both those
# roles. 

 

    if option == "Student":
        with st.form("insert_new_student"): 
            names = st.text_input("First names", max_chars=100)
            pat_surname = st.text_input("Paternal surname", max_chars=100)
            mat_surname = st.text_input("Maternal surname", max_chars=100)
            nationality = st.selectbox("Nationality", nationalities_lst)
            curp = st.text_input("CURP", max_chars=18)
            curp = curp.upper()
            # It seems that streamlit doesn't have a function to force 
            # uppercase on the frontend, but at least I will do it for the 
            # data base. 

            min_date = datetime.date(1926, 1, 1)
            # I think few people would continue studying while being
            # a hundred years old
            max_date = datetime.date.today()
            # I didn't know, but I can put min and max values in date_input
            # just like in the other kinds of inputs. I will make use of the
            # datetime library to create the upper and lower bounds
            birth_date = st.date_input("Birth date", 
            min_value=min_date, max_value=max_date)
            
            email = st.text_input("Personal email")
            telephone = st.text_input("Personal phone number", max_chars=15)
            state_dic = {'AG': 'AS', 'JAL': 'JC', 'MEX': 'CDMX', 'PUE': 'PL', 'QRO': 'QRO'}   
            city = st.selectbox("City", 
            ['AG', 'JAL', 'MEX', 'PUE', 'QRO'])
            state = state_dic[city]
            street = st.text_input("Street")
            ext_num = st.number_input("External number", min_value=1)
            zipcode = st.number_input("Zip Code", min_value=1)
            marital_status = st.radio("Marital Status", maritalstatus_lst)
            blood_type = st.pills("Blood Type", bloodtypes_lst)
            nss = st.number_input("Social Security Number", min_value=10000)
            tutor_id = st.number_input("Tutor ID", min_value=1)
            beginning = st.date_input("Beginning of studies")
            submited = st.form_submit_button()
            chosen_career = st.selectbox("Career", 
            ["Bachelor's in Technology", "Bachelor's in Neurosciences"])
            if chosen_career == "Bachelor's in Technology":
                career_id = 1
            if chosen_career == "Bachelor's in Neurosciences":
                career_id = 2

            if submited:
                query_personal_info = """ 
                INSERT INTO students(
                    first_names, paternal_surname, maternal_surname, 
                    nationality, curp, birth_date, email, telephone,
                    city, state, street, external_number, zip_code,
                    marital_status, blood_type, NSS, tutor_id)

                VALUES (%s, %s, %s,
                %s, %s, %s, %s, %s, 
                %s, %s, %s, %s, %s, 
                %s, %s, %s, %s)

                RETURNING id; 
                """

                person_data = (names, pat_surname, mat_surname, nationality, 
                curp, birth_date, email, telephone, city, state, street, ext_num,
                zipcode, marital_status, blood_type, nss, tutor_id)

                student_id = conn_to_postgres(query_personal_info, 
                params = person_data, fetch = True)

                query_college_info = """ 
                INSERT INTO student_college_info(
                    student_id, career_id, code, beginning, semester, status, 
                    regularity, ins_email, credits, titulation)
                
                VALUES(%s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s);
                """

                code = random.randint(100000000, 999999999)
                ins_email = f"{names}.{code}@comunidad.unam.mx"
                status = status_lst[0]
                isregular = True
                titulation = None
                # I will leave every new student simply as active, as it
                # doesn't make sense to have other status for a new 
                # student. I should probably move these up, as for them to
                # be formatted one after the other... beginning is the only
                # part that is going to be formatted to the page. I will move
                # just that. 

                college_data = (student_id, career_id, code, beginning, 1,
                status, isregular, ins_email, 0, titulation)

                conn_to_postgres(query_college_info, college_data)

                st.success("Student created succesfully")
                # Lets see how this method renders. It looks good. 

                st.rerun()
                # In case the ttl argument fails. 

                # I need to force uppercase on CURP. 
                # The calendar just goes 10 years before and after, 
                # I need to expand the range at least on birth date. 

# Just as in number_input you can put a minimum value, with
# text_input I can put a limit on characters! I will simply put the
# same limit that I left on the original table. 

# I was putting the variable without actually having any way for 
# sql to know what the content of the variable was, but I found 
# it extremely interesting to note that people use f-strings! 

# I think I might be getting trouble because there are libraries
# and lists that are not on `app.py` but on `main.ipynb`. For that 
# reason I will just put all the lists on top of the file

# There is an error on my insert logic related to the birthdate. 
# First of all, I don't even know if the data I obtained from 
# streamlit is formatted in the YYYY-MM-DD format postgres wants. 
# The other problem is that the math on the beginning year gets messy
# I should probably just include another date_input there. 
 