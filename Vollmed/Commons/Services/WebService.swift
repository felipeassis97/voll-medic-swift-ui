//
//  WebService.swift
//  Vollmed
//
//  Created by Felipe Assis on 09/01/24.
//

import UIKit

struct WebService {
    
    private let baseURL = "http://localhost:3000"
    
    let authManager = AuthManager.instance

    func logoutPatient() async throws -> Bool {
        let endpoint = baseURL + "/auth/logout"
        guard let url = URL(string: endpoint) else { return false }
        guard let token = authManager.token else { return false}

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (_, response) =  try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return true
            }
            return false
        } catch {
            print("Error when logout patient: \(error)")
            return false
        }
        
    }
    
    
    func loginPatient(email: String, password: String) async throws -> LoginResponse? {
        let endpoint = baseURL + "/auth/login"
        guard let url = URL(string: endpoint) else { return nil }
        
        let credentials = LoginRequest(email: email, password: password)
     
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(credentials)
            
            let (data, response) =  try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return try JSONDecoder().decode(LoginResponse.self, from: data)
            }
            return nil
        } catch {
            print("Error when login patient: \(error)")
            return nil
        }
    }

    func registerPatient(patient: Patient) async throws -> Bool {
        let endpoint = baseURL + "/paciente"
        guard let url = URL(string: endpoint) else { return false }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(patient)
            
            let (_, response) =  try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 202 {
                return true
            }
            return false
        } catch {
            print("Error when register patient: \(error)")
            return false
        }
    }
    
    func cancelAppointment(appointmentID: String,
                           reasonToCancel: String) async throws -> Void {
        let endpoint = baseURL + "/consulta/" + appointmentID
        guard let url = URL(string: endpoint) else { return }
        guard let token = authManager.token else { return }

        do {
            let requestData: [String: Any] = ["motivo_cancelamento" : reasonToCancel]
            let jsonBody = try JSONSerialization.data(withJSONObject: requestData)
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = jsonBody
            
            let (_, response) =  try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return
            }
            
        } catch {
            print("Error when delete appointment: \(error)")
        }
    }
    
    func reescheduleAppointment(appointmentID: String, newDate: String) async throws -> ScheduleAppointmentResponse? {
        let endpoint = baseURL + "/consulta/" + appointmentID
        guard let url = URL(string: endpoint) else { return nil }
        guard let token = authManager.token else { return nil }

        do {
            let requestData: [String: Any] = ["data" : newDate]
            let jsonBody = try JSONSerialization.data(withJSONObject: requestData)
            
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = jsonBody
            
            let (data, _) =  try await URLSession.shared.data(for: request)
            let appointments = try JSONDecoder().decode(ScheduleAppointmentResponse.self, from: data)
            return appointments
        } catch {
            print("Error when reeschedule appointment: \(error)")
            return nil
        }
    }
    
    
    func getAllApointmentsFromPatient(patientID: String) async throws -> [Appointment]? {
        let endpoint = baseURL + "/paciente/" + patientID + "/consultas"
        guard let url = URL(string: endpoint) else { return nil }
        
        guard let token = authManager.token else { return nil }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
            let (data, _) =  try await URLSession.shared.data(for: request)
            let schedules = try JSONDecoder().decode([Appointment].self, from: data)
            return schedules
        } catch {
            print("Error when get appointment by user: \(error)")
            return nil
        }
    }
    
    func scheduleAppointment(specialistID: String,
                             patientID: String,
                             date: String) async throws -> ScheduleAppointmentResponse? {
        
        let endpoint = baseURL + "/consulta"
        guard let url = URL(string: endpoint) else { return nil }
        
        guard let token = authManager.token else { return nil }
        
        do {
            let appointment = ScheduleAppointmentRequest(specialistID: specialistID, patientID: patientID, date: date)
            let body = try JSONEncoder().encode(appointment)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = body
            
            let (data, _) =  try await URLSession.shared.data(for: request)
            let appointments = try JSONDecoder().decode(ScheduleAppointmentResponse.self, from: data)
            return appointments
        } catch {
            print("Error when schedule appointment: \(error)")
            return nil
        }
    }
    
    func dowloadImage(from imageURL: String) async throws -> UIImage? {
        
        let imageCache = NSCache<NSString, UIImage>()
        guard let url = URL(string: imageURL) else { return UIImage(named: "Logo") ?? nil }
        
        //Check if exists in cache
        if let cachedImage = imageCache.object(forKey: imageURL as NSString) {
            return cachedImage
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image =  UIImage(data: data) else {
                return UIImage(named: "Logo") ?? nil
            }
            //Save in cache
            imageCache.setObject(image, forKey: imageURL as NSString)
            return image
        }
        catch {
            print("Error when download image: \(error)")
            return UIImage(named: "Logo") ?? nil
        }
    }
    
    func getAllSpecialists() async throws -> [Specialist]? {
        let endpoint = baseURL + "/especialista"
        guard let url = URL(string: endpoint) else { return nil }
        do {
            let (data, _) =  try await URLSession.shared.data(from: url)
            let specialists = try JSONDecoder().decode([Specialist].self, from: data)
            return specialists
        } catch {
            print("Error when get all specialists: \(error)")
            return nil
        }
    }
}