CREATE OR REPLACE FUNCTION generate_appointments(_schedules_id INT) RETURNS VOID AS $$
DECLARE
    doctor_id INT;
    work_date DATE;
    start_time TIME;
    end_time TIME;
    appointment_length INTERVAL;
    current_start TIMESTAMP;
    current_end TIMESTAMP;
BEGIN
    SELECT s.doctor_id, s.work_date, s.start_time, s.end_time, s.appointment_length
    INTO doctor_id, work_date, start_time, end_time, appointment_length
    FROM schedules s
    WHERE s.id = _schedules_id;

    current_start := work_date::TIMESTAMP + start_time;
    current_end := current_start + appointment_length;

    WHILE current_end <= (work_date::TIMESTAMP + end_time) LOOP
        INSERT INTO appointments (doctor_id, start_time, end_time, status)
        VALUES (doctor_id, current_start, current_end, 'available');
        
        current_start := current_end;
        current_end := current_start + appointment_length;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger_generate_appointments() RETURNS TRIGGER AS $$
BEGIN
    PERFORM generate_appointments(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER generate_appointments_trigger
AFTER INSERT ON schedules
FOR EACH ROW
EXECUTE FUNCTION trigger_generate_appointments();

