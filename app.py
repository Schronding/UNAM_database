import streamlit as st
import pandas as pd
import os
import psycopg

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
    all_students = st_conn.query("SELECT * FROM students;")
    st.dataframe(all_students)

# Wow, I didn't expect it to be that easy. streamlit built a beautiful
# data frame with just 3 lines of code. I have 19 students though, 
# I need to check that

elif selected_option == "b. Professors":
    st.header("All the professors of the ENES")
    all_professors = st_conn.query("SELECT * FROM professors;")
    st.dataframe(all_professors)

elif selected_option == "c. Regularity":
    st.header("Regular and irregular students")
    students_college = st_conn.query(""" 
    JOIN students s, student_college_info sci
    WHERE s.id = sci.student_id AS
    students_college_combined WHERE
    s.first_names
    s.paternal_surname
    s.maternal_surname
    sci.credits
    sci.regularity
    sci.semester; 
    """)

    regulars = st_conn.query("""
    SELECT * FROM students_college_combined
    WHERE student_college_info.regularity = TRUE
    """)
    st.text("### Regulars")
    st.dataframe(regulars)

    iregulars = st_conn.query("""
    SELECT * FROM students_college_combined
    WHERE student_college_info.regularity = TRUE
    """)
    st.text("### Iregulars")
    st.dataframe(iregulars)

elif selected_option == "d. Approved":
    st.header("Approved subjects by each student")
    student = st.form("What student do you wish to look up?")
    st.form_submit_button("Look up")
    approved_subjects = st_conn.query("""
    SELECT * FROM taken_subjects 
    WHERE student = student_id 
    AND acreditation = TRUE;
    """)
    st.dataframe(approved_subjects)

# streamlit.errors.StreamlitAPIException: st.form_submit_button() must be used inside an st.form().
# It seems that putting the submit button immediately below the form
# is not enough, I suppose that the button should be a variable used
# in form

elif selected_option == "e. Missing":
    st.markdown("# Subjects to be accredited")
    failed = st_conn.query(""" 
    SELECT * FROM taken_subjects
    WHERE accreditation = FALSE;
    """)
    remaining = st_conn.query("""
        SELECT * FROM subjects
    """)

elif selected_option == "f. Subjects":
    st.markdown("# Subjects that the professor taught")
    professor = st.form("What student do you wish to look up?")
    st.form_submit_button("Look up")
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
    names = st.text_input("First names")
    pat_surname = st.text_input("Paternal surname")
    mat_surname = st.text_input("Maternal surname")
    nationality = st.selectbox("Pick one",
    ['MX', 'DE', 'AD', 'AR', 'AU', 'AT', 'BE', 'BO', 'BR', 'CA'])
    curp = st.text_input("CURP")
    birth_date = st.date_input("Birth date")
    email = st.text_input("Personal email")
    telephone = text_input("Personal phone number")
    state_dic = {'AG': 'AS', 'JAL': 'JC', 'MEX': 'CDMX', 'PUE': 'PL', 'QRO': 'QRO'}   
    city = st.selectbox("Pick one", 
    ['AG', 'JAL', 'MEX', 'PUE', 'QRO'])
    state = state_dic[city]
    street = st.text_input("Street")
    ext_num = st.text_input("External number")
    zipcode = st.text_input("Zip Code")
    maritalstatus = st.radio("Pick one", 
    ['Single', 'Married', 'Divorced', 'Widowed','Separated'])
    bloodtype = st.pills("Pick one", 
    ['A+','A-', 'B+','B-','O+','O-','AB+','AB-'])
    nss = st.text_input()

# names = ['Jose', 'Mario', 'Rogelio', 'Yamil', 'Hector', 'Alicia','Paola', 'Valeria', 'Valentina', 'Maria']
# surnames = ['Ramirez', 'Martinez', 'Espiritu', 'Gomez', 'Godinez', 'Coronel', 'Herrera', 'Boneta', 'Islas']
# nationalities = ['MX', 'DE', 'AD', 'AR', 'AU', 'AT', 'BE', 'BO', 'BR', 'CA']
# cities = ['AG', 'JAL', 'MEX', 'PUE', 'QRO'] # The city will be the capital
# # of each of these states
# bloodtype = 
# maritalstatus = 
# status_lst = ['active', 'temporal_leave', 'definite_leave', 'graduated', 'titulated']
 