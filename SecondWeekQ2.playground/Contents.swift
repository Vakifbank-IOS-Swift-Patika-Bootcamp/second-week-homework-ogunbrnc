import Foundation

protocol Sitter {
    var id: String { get }
    var name: String { get }
    var animals: [any Animal]? { get set}
    var salary: Double { get }
}

class SitterImp: Sitter {
    let id: String
    var name: String
    var animals: [Animal]?
    var salary: Double {
        Double(animals!.count * 750)
    }
    
    init(name:String = "Unknown"){
        self.animals = []
        self.id = UUID().uuidString
        self.name = name
    }
}

protocol Animal {
    var id: String { get }
    var name: String {get}
    var waterConsumption: Double { get }
    var sitter: (any Sitter)? { get set}
    func speak()
}

class Dog: Animal {
    let id: String
    var name: String
    var waterConsumption: Double
    var sitter: Sitter?
    
    func speak() {
        print("Woof!!")
    }
    
    init(name: String  = "Unknown", waterConsumption: Double) {
        self.id = UUID().uuidString
        self.name = name
        self.waterConsumption = waterConsumption
    }
}
class Cat: Animal {
    let id: String
    var name: String
    var waterConsumption: Double
    var sitter: Sitter?
    
    func speak() {
        print("Meow!!")
    }
    
    init(name: String = "Unknown", waterConsumption: Double) {
        self.id = UUID().uuidString
        self.name = name
        self.waterConsumption = waterConsumption
    }
}

// Some restrictions have been applied

protocol Zoo {
    var waterLimit: Double { get }
    var animals: [any Animal] { get }
    var sitters: [any Sitter] { get }
    var totalSalaries: Double { get }
    
    func add(income  amount: Double, completion: @escaping (Result<Double, Error>) -> Void)
    func add(expense amount: Double, completion: @escaping (Result<Double, Error>) -> Void)
    func add(animal: Animal, completion: @escaping (Result<Animal, Error>) -> Void)
    func add(sitter: Sitter,completion: @escaping (Result<Sitter, Error>) -> Void)
    func increase(water amount: Double, completion: @escaping (Result<Double, Error>) -> Void)
    func paySalaries(completion: @escaping (Result<Double, Error>) -> Void)
    func assign(animal: inout Animal, sitter: inout Sitter, completion: @escaping (Result<(Sitter,Animal), Error>) -> Void)

}

enum ZooError: Error {
    case incomeNotPositive
    case expenseNotPositive
    case notEnoughBudget
    case sitterNotExists
    case animalNotExists
    case animalExists
    case sitterExists
    case limitNotPossitive
    case notEnoughWater
    case hasAlreadySitter
}

extension ZooError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .incomeNotPositive:
            return "Income amount have to be a positive value."
        case .expenseNotPositive:
            return "Expense amount have to be a positive value."
        case .notEnoughBudget:
            return "Not enough budget to pay."
        case .animalExists:
            return "Animal is already added"
        case .animalNotExists:
            return "This animal does not live in the zoo."
        case .sitterNotExists:
            return "This sitter doesn't work at the zoo."
        case .sitterExists:
            return "Sitter is already added."
        case .limitNotPossitive:
            return "Water limit have to be a positive value."
        case .notEnoughWater:
            return "There is no enough water to add new animal."
        case .hasAlreadySitter:
            return "This animal has already sitter"
        }
    }
}

class ZooImpl: Zoo {
    
    var waterLimit: Double
    var budget: Double
    var animals: [Animal]
    var sitters: [Sitter]
    var totalSalaries: Double {
        sitters.reduce(0) { $0 + $1.salary }
    }
    
    //Restriction: income can not be negative
    func add(income amount: Double, completion: @escaping (Result<Double, Error>) -> Void) {
        guard amount > 0 else {
            let error = ZooError.incomeNotPositive
            completion(.failure(error))
            return
        }
        budget += amount
        completion(.success(budget))
    }
    
    //Restriction: expense can not be negative and can not be greater than budget.
    func add(expense amount: Double, completion: @escaping (Result<Double, Error>) -> Void) {
        guard amount > 0 else {
            let error = ZooError.expenseNotPositive
            completion(.failure(error))
            return
        }
        guard budget >= amount else {
            let error = ZooError.notEnoughBudget
            completion(.failure(error))
            return
        }
        
        budget -= amount
        completion(.success(budget))
    }
    
    //Restriction: If the water limit is not sufficient or animal is already in zoo, new animal cannot be added
    func add(animal: Animal, completion: @escaping (Result<Animal, Error>) -> Void) {
        let contains = animals.contains { $0.id == animal.id }
        guard !contains else {
            let error = ZooError.animalExists
            completion(.failure(error))
            return
        }
        
        guard waterLimit >= animal.waterConsumption  else {
            completion(.failure(ZooError.notEnoughWater))
            return
        }
        animals.append(animal)
        waterLimit -= animal.waterConsumption
        completion(.success(animal))
    }
    
    // Restriction: If the sitter is already added, will not be added again.
    func add(sitter: Sitter,completion: @escaping (Result<Sitter, Error>) -> Void) {
        let contains = sitters.contains { $0.id == sitter.id }
        guard !contains else {
            let error = ZooError.sitterExists
            completion(.failure(error))
            return
        }
        sitters.append(sitter)
        completion(.success(sitter))
    }
    
    //Restriction: water amount can not be negative
    func increase(water amount: Double, completion: @escaping (Result<Double, Error>) -> Void) {
        guard amount > 0 else {
            let error = ZooError.limitNotPossitive
            completion(.failure(error))
            return
        }
        waterLimit += amount
        completion(.success(waterLimit))
    }
    
    //Restriction: If the budget is not sufficient, no payment will be made.
    func paySalaries(completion: @escaping (Result<Double, Error>) -> Void) {
        guard budget >= totalSalaries else {
            let error = ZooError.notEnoughBudget
            completion(.failure(error))
            return
        }
        
        budget -= totalSalaries
        completion(.success(budget))
    }
    
    // Restriction: if animal doesn't live at the zoo or sitter doesn't work at the zoo or animal has already sitter assignment will not be made
    func assign(animal: inout Animal, sitter: inout Sitter, completion: @escaping (Result<(Sitter,Animal), Error>) -> Void) {
        guard animals.contains(where: {$0.id == animal.id}) else {
            completion(.failure(ZooError.animalNotExists))
            return
        }
        guard sitters.contains(where: {  $0.id == sitter.id}) else {
            completion(.failure(ZooError.sitterNotExists))
            return
        }
        guard animal.sitter == nil else {
            completion(.failure(ZooError.hasAlreadySitter))
            return
        }
        animal.sitter = sitter
        sitter.animals!.append(animal)
        completion(.success((sitter,animal)))
    }
    
    func prints(){
        animals.forEach { animal in
            print(animal.waterConsumption)
        }
        sitters.forEach { sitter in
            print(sitter.salary)
        }
    }
    //If there are animals while the zoo is being created, water limits will be deducted.
    init(waterLimit:Double, budget: Double , animals: [Animal], sitters: [Sitter]){
        self.waterLimit = waterLimit - animals.reduce(0) { $0 + $1.waterConsumption }
        self.budget = budget
        self.animals = animals
        self.sitters = sitters
    }
}

//All the scenarios I can see have been tried below.

var sit1: Sitter = SitterImp(name: "Oguz")
var sit2: Sitter = SitterImp(name: "Osman")
var sit3: Sitter = SitterImp(name: "Ogun")

var dog1: Animal = Dog(name: "Karabas",waterConsumption: 3)
var dog2: Animal = Dog(name: "Zeytin", waterConsumption: 3)
var dog3: Animal = Dog(name: "Pasa", waterConsumption: 10)

var cat1: Animal = Cat(name: "Boncuk",waterConsumption: 2)
var cat2: Animal = Cat(name: "Duman", waterConsumption: 2)

var zoo = ZooImpl(waterLimit: 15, budget: 3_000, animals: [dog1,cat1], sitters: [sit1])

//Add new sitter to zoo.
zoo.add(sitter: sit2) { result in
    switch result {
    case .success(let sitter):
        print("\(sitter.name) added to zoo!!")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//If we try to add same sitter again.
zoo.add(sitter: sit1) { result in
    switch result {
    case .success(let sitter):
        print("\(sitter.name) added to zoo!!")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//Add new animal to zoo.
zoo.add(animal: dog2) { result in
    switch result {
    case .success(let animal):
        print("\(animal.name) added to zoo!!")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//If we try to add same animal again.
zoo.add(animal: dog2) { result in
    switch result {
    case .success(let animal):
        print("\(animal.name) added to zoo!!")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//Assign sitter to animal.
zoo.assign(animal: &dog1, sitter: &sit1) { result in
    switch result {
    case .success((let sitter, let animal)):
        print("\(sitter.name) assigned to \(animal.name) as sitter")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//If we try to assign sitter to animal and animal has already sitter.
zoo.assign(animal: &dog1, sitter: &sit2) { result in
    switch result {
    case .success((let sitter, let animal)):
        print("\(sitter.name) assigned to \(animal.name) as sitter")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//If we try to assign sitter to animal and animal doesn't live in zoo.
zoo.assign(animal: &dog3, sitter: &sit2) { result in
    switch result {
    case .success((let sitter, let animal)):
        print("\(sitter.name) assigned to \(animal.name) as sitter")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//If we try to assign sitter to animal and sitter doesn't work in zoo.
zoo.assign(animal: &dog2, sitter: &sit3) { result in
    switch result {
    case .success((let sitter, let animal)):
        print("\(sitter.name) assigned to \(animal.name) as sitter")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

// If we don't have enough water to add more animals and we try.
zoo.add(animal: dog3) { result in
    switch result {
    case .success(let animal):
        print("\(animal.name) added to zoo!!")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

zoo.add(expense: 250.0) { result in
    switch result {
    case .success(let budget):
        print("Completed! New budget is \(budget)")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//If we don't have enough money to add expense.
zoo.add(expense: 3000.0) { result in
    switch result {
    case .success(let budget):
        print("Completed! New budget is \(budget)")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//Add income.
zoo.add(income: 3000.0) { result in
    switch result {
    case .success(let budget):
        print("Completed! New budget is \(budget)")
    case .failure(let error):
        print(error.localizedDescription)
    }
}
zoo.increase(water: 30) { result in
    switch result {
    case .success(let waterLimit):
        print("Completed! New daily water limit is \(waterLimit)")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

zoo.paySalaries { result in
    switch result {
    case .success(let budget):
        print("Completed! New budget is \(budget)")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

// If we don't have enough money to pay salary
zoo.add(expense: 5000.0) { result in
    switch result {
    case .success(let budget):
        print("Completed! New budget is \(budget)")
    case .failure(let error):
        print(error.localizedDescription)
    }
}
zoo.paySalaries { result in
    switch result {
    case .success(let budget):
        print("Completed! New budget is \(budget)")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

// Animal is talking..

cat1.speak()
dog1.speak()





