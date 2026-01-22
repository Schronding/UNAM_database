import streamlit as st
import pandas as pd
import os
import psycopg
from dotenv import load_dotenv
import random
import string 


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

st_conn = st.connection("postgresql", type = "sql")
st.title("UNAM Database")
selected_option = st.sidebar.selectbox("Action", ["a. Students", 
"b. Professors", "c. Regularity", "d. Approved", "e. Missing", 
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
    all_students = st_conn.query("SELECT * FROM student_college_info;")
    st.dataframe(all_students)
    st.markdown("### Select Career")
    selected_option = st.segmented_control("Career", 
    ["Bachelor's in Technology", "Bachelor's in Neurosciences"])
    if selected_option == "Bachelor's in Technology":
        technology_students = st_conn.query("""
        SELECT * FROM student_college_info sci
        WHERE sci.career_id = 1;
        """)
        st.dataframe(technology_students)

    if selected_option == "Bachelor's in Neurosciences":
        neuroscience_students = st_conn.query("""
        SELECT * FROM student_college_info sci
        WHERE sci.career_id = 2;
        """)
        st.dataframe(neuroscience_students)
    

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

elif selected_option == "b. Professors":
    st.header("All the professors of the ENES")
    all_professors = st_conn.query("SELECT * FROM professors;")
    st.dataframe(all_professors)

elif selected_option == "c. Regularity":
    st.header("Regular and irregular students")
    choices = st.multiselect("Select the options", 
    ["Regulars", "Irregulars", 
    "Bachelor's in Technology", "Bachelor's in Neurosciences"])
    students_college = st_conn.query(""" 
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

    if "Regulars" in choices:
        st.dataframe(students_college[students_college.regularity == True])
    if choices == "Irregulars":
        st.dataframe(students_college[students_college.regularity == False])
    if (choices == "Regulars" and choices == "Irregulars") or (choices == "Bachelor's in Neurosciences" and choices == "Bachelor's in Technology"):
        st.dataframe(students_college)
    if choices == "Bachelor's in Technology":
        st.dataframe(students_college[students_college.career_id == 1])
    if choices == "Bachelor's in Neurosciences":
        st.dataframe(students_college[students_college.career_id == 2])
    if choices == "Bachelor's in Technology" and choices == "Regulars":
        st.dataframe(students_college[students_college.career_id == 1, students_college.regularity == True])
    if choices == "Bachelor's in Technology" and choices == "Irregulars":
        st.dataframe(students_college[students_college.career_id == 1, students_college.regularity == False])
    if choices == "Bachelor's in Neurosciences" and choices == "Regulars":
        st.dataframe(students_college[students_college.career_id == 2, students_college.regularity == True])
    if choices == "Bachelor's in Neurosciences" and choices == "Irregulars":
        st.dataframe(students_college[students_college.career_id == 2, students_college.regularity == False])

    

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

elif selected_option == "d. Approved":
    st.header("Approved subjects by each student")
    with st.form("approved_subjects"):
        student_id = st.text_input("What student do you wish to look up?")
        submited = st.form_submit_button("Look up")
        if submited:
            approved_subjects = st_conn.query(f"""
            SELECT * FROM taken_subjects 
            WHERE {student_id} = student_id 
            AND acreditation = TRUE;
            """)

            st.dataframe(approved_subjects)

# streamlit.errors.StreamlitAPIException: st.form_submit_button() must be used inside an st.form().
# It seems that putting the submit button immediately below the form
# is not enough, I suppose that the button should be a variable used
# in form

# Indeed it needs to be put there, but not as I thought. To work 
# corretly form, the button and the input text (which I did not put)
# must be inside a with block. 

elif selected_option == "e. Remaining":
    st.markdown("# Subjects to be accredited")
    with st.form("remaining_subjects_per_student"):
        student_id = st.number_input("Student ID", min_value=1, step=1)
        submitted = st.form_submit_button("Check remaining subjects")
        if submitted:
            career_check = conn_to_postgres(f"""
            SELECT career_id
            FROM student_college_info 
            WHERE student_id = {student_id};
            """, fetch=True)
            print(career_check)



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
    with st.form("professor_id"):
        professor = st.form("What professor do you wish to look up?")
        submited = st.form_submit_button("Look up")
        if submited:
            complete_clases = st_conn.query("""
            JOIN subjects s, professors p , classes c AS
            complete_clases
            c.professor_id,
            s.name,
            p.first_names,
            p.paternal_surname,
            p.maternal_surname, 
            c.semester,
            s.credits;
            """)
            taught_subjects = st_conn.query(""" 
            SELECT * FROM complete_clases
            WHERE professor = professor_id;
            """)

elif selected_option == "4. Insert":
    st.markdown("# Insert new professors or students")
    option = st.segmented_control("You want to create a...", ["Student", "Professor"])
    if option == "Professor":
        with st.form("insert_new_professor"):
            names_lst = st.text_input("First names", max_chars=100)
            pat_surname = st.text_input("Paternal surname", max_chars=100)
            mat_surname = st.text_input("Maternal surname", max_chars=100)
            submited = st.form_submit_button()
            if submited:
                insert_professor_query = (""" 
                INSERT INTO professors(first_names, paternal_surname, maternal_surname)
                VALUES(%s, %s, %s);
                """)

                professor_values = (names_lst, pat_surname, mat_surname)
                conn_to_postgres(insert_professor_query, professor_values)

    if option == "Student":
        with st.form("insert_new_student"): 
            names_lst = st.text_input("First names", max_chars=100)
            pat_surname = st.text_input("Paternal surname", max_chars=100)
            mat_surname = st.text_input("Maternal surname", max_chars=100)
            nationality = st.selectbox("Pick one", nationalities_lst)
            curp = st.text_input("CURP", max_chars=30)
            birth_date = st.date_input("Birth date")
            email = st.text_input("Personal email")
            telephone = st.text_input("Personal phone number", max_chars=15)
            state_dic = {'AG': 'AS', 'JAL': 'JC', 'MEX': 'CDMX', 'PUE': 'PL', 'QRO': 'QRO'}   
            city = st.selectbox("City", 
            ['AG', 'JAL', 'MEX', 'PUE', 'QRO'])
            state = state_dic[city]
            street = st.text_input("Street")
            ext_num = st.number_input("External number", min_value=1)
            zipcode = st.number_input("Zip Code", min_value=1)
            maritalstatus = st.radio("Pick one", maritalstatus_lst)
            bloodtype = st.pills("Pick one", bloodtypes_lst)
            nss = st.number_input("Social Security Number", min_value=10000)
            tutor_id = st.number_input("Tutor ID", min_value=1)
            submited = st.form_submit_button()
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

                person_data = (chosen_name, chs_pat_name, chs_mat_name, nationality, 
                chs_curp, birth_date, email, telephone, city, state, street, ext_num,
                zipcode, marital_status, blood_type, nss, tutor)

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
                beginning = str(int(birth_date[:4]) + 20) + birth_date[4:]
                ins_email = f"{chosen_name}.{code}@comunidad.unam.mx"
                status = random.choice(status_lst)

                college_data = (student_id, plan_id, code, beginning, 1,
                status, isregular, ins_email, 0, None)

                conn_to_postgres(query_college_info, college_data)

# Just as in number_input you can put a minimum value, with
# text_input I can put a limit on characters! I will simply put the
# same limit that I left on the original table. 

# I was putting the variable without actually having any way for 
# sql to know what the content of the variable was, but I found 
# it extremely interesting to note that people use f-strings! 

# I think I might be getting trouble because there are libraries
# and lists that are not on `app.py` but on `main.ipynb`. For that 
# reason I will just put all the lists on top of the file


 