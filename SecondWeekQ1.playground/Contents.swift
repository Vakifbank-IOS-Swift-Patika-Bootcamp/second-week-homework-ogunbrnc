import Foundation

enum MaritalStatus: Int, Equatable {
    case single
    case married
}

// Salary will be calculated using salary Coefficient value
enum EmployeeType: Int, Equatable {
    case junior
    case mid
    case senior
    
    var salaryCoefficient: Double {
        switch self {
        case .junior:
            return 1
        case .mid:
            return 1.5
        case .senior:
            return 2
        }
    }
}

// Using the ID value, the same employee will not be added again.

protocol Employee: Equatable {
    var id: String { get }
    var name: String { get }
    var age: Int { get }
    var maritalStatus: MaritalStatus? { get set }
    var type: EmployeeType { get }
    var salary: Double { get }
}

struct EmployeeImpl: Employee {
    let id: String
    let name: String
    let age: Int
    var maritalStatus: MaritalStatus?
    let type: EmployeeType

    init(name: String, age: Int, maritalStatus: MaritalStatus?, type: EmployeeType) {
        id = UUID().uuidString
        self.name = name
        self.age = age
        self.maritalStatus = maritalStatus
        self.type = type
    }

    var salary: Double {
        10_000 * type.salaryCoefficient + Double(100 * age)
    }
}

protocol Company {
    var name: String { get }
    var employees: [any Employee] { get }
    var budget: Double { get }
    var foundationYear: Int { get }

    mutating func add(income amount: Double, completion: @escaping (Result<Double, Error>) -> Void)
    mutating func add(expense amount: Double, completion: @escaping (Result<Double, Error>) -> Void)
    mutating func add(employee: any Employee, completion: @escaping (Result<any Employee, Error>) -> Void)
    mutating func paySalaries(completion: @escaping (Result<Double, Error>) -> Void)
}

enum CompanyError: Error {
    case incomeNotPositive
    case expenseNotPositive
    case notEnoughBudget
    case employeeExists
}

extension CompanyError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .incomeNotPositive:
            return "Income amount have to be a positive value."
        case .expenseNotPositive:
            return "Expense amount have to be a positive value."
        case .notEnoughBudget:
            return "Not enough budget to pay."
        case .employeeExists:
            return "Employee is already added."
        }
    }
}

struct CompanyImpl: Company {
    let name: String
    var employees: [any Employee]
    var budget: Double
    let foundationYear: Int
    
    private var totalSalaries: Double {
        employees.reduce(0) { $0 + $1.salary }
    }
    
    // Restriction: income can not be negative
    mutating func add(income amount: Double, completion: @escaping (Result<Double, Error>) -> Void) {
        guard amount > 0 else {
            let error = CompanyError.incomeNotPositive
            completion(.failure(error))
            return
        }
        budget += amount
        completion(.success(budget))
    }
    
    // Restriction: expense can not be negative and greater than budget.
    mutating func add(expense amount: Double, completion: @escaping (Result<Double, Error>) -> Void) {
        guard amount > 0 else {
            let error = CompanyError.expenseNotPositive
            completion(.failure(error))
            return
        }
        guard budget >= amount else {
            let error = CompanyError.notEnoughBudget
            completion(.failure(error))
            return
        }
        
        budget -= amount
        completion(.success(budget))
    }
    
    // Restriction: Same employee can not be added.
    mutating func add(employee: any Employee, completion: @escaping (Result<any Employee, Error>) -> Void) {
        let contains = employees.contains { $0.id == employee.id }
        guard !contains else {
            let error = CompanyError.employeeExists
            completion(.failure(error))
            return
        }
        employees.append(employee)
        completion(.success(employee))
    }
    // Restriction: If the total amount of salary to be paid is more than the budget, the payment cannot be made.
    mutating func paySalaries(completion: @escaping (Result<Double, Error>) -> Void) {
        guard budget >= totalSalaries else {
            let error = CompanyError.notEnoughBudget
            completion(.failure(error))
            return
        }
        
        budget -= totalSalaries
        completion(.success(budget))
    }
}
//All the scenarios I can see have been tried below.

var jr1 = EmployeeImpl(name: "Ogun", age: 23, maritalStatus: .single, type: .junior)
var mid1 = EmployeeImpl(name: "Oguz", age: 29, maritalStatus: .married, type: .mid)
var sr1 = EmployeeImpl(name: "Osman", age: 61, maritalStatus: .married, type: .senior)
var company = CompanyImpl(name: "Birinci Fam", employees: [jr1,mid1], budget: 20_000, foundationYear: 1999)

// Add new employee with add function.
company.add(employee: sr1) { result in
    switch result {
    case .success(let employee):
        print("\(employee.name) added to company!!")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

// If the employee is already added.
company.add(employee: sr1) { result in
    switch result {
    case .success(let employee):
        print("\(employee.name) added to company!!")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

company.add(expense: 15_000) { result in
    switch result {
    case .success(let budget):
        print("Completed! New budget is \(budget)")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//If the budget is not enough to expense.
company.add(expense: 15_000) { result in
    switch result {
    case .success(let budget):
        print("Completed! New budget is \(budget)")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

company.add(income: 65_000) { result in
    switch result {
    case .success(let budget):
        print("Completed! New budget is \(budget)")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

company.paySalaries { result in
    switch result {
    case .success(let budget):
        print("Completed! New budget is \(budget)")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//If the budget is not enough to pay salaries.
company.paySalaries { result in
    switch result {
    case .success(let budget):
        print("Completed! New budget is \(budget)")
    case .failure(let error):
        print(error.localizedDescription)
    }
}
