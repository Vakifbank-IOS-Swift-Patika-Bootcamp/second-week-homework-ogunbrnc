import Foundation

//When the sitter is created, the animals array can be empty and then the animal can be assigned with the assign function.
// Or if there is a previously created animal, it can be assigned with animals array in the sitter initialization.
protocol Sitter {
    var id: String { get }
    var name: String? { get }
    var animals: [any Animal] { get}
    var salary: Double { get }
    
    func assign(animal: inout Animal, completion: @escaping (Result<Animal, Error>) -> Void)
}

enum SitterError: Error {
    case hasAlreadySitter
}

extension SitterError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .hasAlreadySitter:
            return "This animal has already a sitter."
        }
    }
}

class SitterImp: Sitter {
    let id: String
    var name: String?
    var animals: [Animal]
    var salary: Double {
        Double(animals.count * 750)
    }
    
    //Sitter assignment to animals added with the assign function is also done here if animal has no sitter.
    func assign(animal: inout Animal, completion: @escaping (Result<Animal, Error>) -> Void) {
        guard animal.sitter == nil else {
            completion(.failure(SitterError.hasAlreadySitter))
            return
        }
        animal.sitter = self
        animals.append(animal)
        completion(.success(animal))
    }
    //Sitter assignment to animals added with the constructor and assign function is also done here.
    init(name:String? = "Unknown", animals: [Animal]){
        self.id = UUID().uuidString
        self.name = name
        self.animals = animals
        assignAsSitter()
    }
    
    private func assignAsSitter(){
        animals.indices.forEach {
            if animals[$0].sitter == nil {
                animals[$0].sitter = self
                print("\(self.name!) appointed to \(animals[$0].name!) as sitter.")
            }
        }
    }
    
}

protocol Animal {
    var name: String? {get}
    var waterConsumption: Double { get }
    var sitter: (any Sitter)? { get set}
    
    func speak()
}

class Dog: Animal {
    var name: String?
    var waterConsumption: Double
    var sitter: Sitter?
    
    func speak() {
        print("Woof!!")
    }
    
    init(name: String? = "Unknown", waterConsumption: Double) {
        self.name = name
        self.waterConsumption = waterConsumption
    }
}
class Cat: Animal {
    var name: String?
    var waterConsumption: Double
    var sitter: Sitter?
    
    func speak() {
        print("Meow!!")
    }
    
    init(name: String? = "Unknown", waterConsumption: Double) {
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

}

enum ZooError: Error {
    case incomeNotPositive
    case expenseNotPositive
    case notEnoughBudget
    case sitterExists
    case limitNotPossitive
    case notEnoughWater
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
        case .sitterExists:
            return "Sitter is already added."
        case .limitNotPossitive:
            return "Water limit have to be a positive value."
        case .notEnoughWater:
            return "There is no enough water to add new animal."
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
    //Restriction: If the water limit is not sufficient, new animals cannot be added.

    func add(animal: Animal, completion: @escaping (Result<Animal, Error>) -> Void) {
        let remainingWaterConsumption = waterLimit - animal.waterConsumption
        guard remainingWaterConsumption >= animal.waterConsumption else {
            completion(.failure(ZooError.notEnoughWater))
            return
        }
        animals.append(animal)
        waterLimit -= animal.waterConsumption
        completion(.success(animal))
    }
    // Restriction: If the budget is not sufficient, new caregivers cannot be added.
    func add(sitter: Sitter,completion: @escaping (Result<Sitter, Error>) -> Void) {
        let contains = sitters.contains { $0.id == sitter.id }
        guard !contains else {
            let error = ZooError.sitterExists
            completion(.failure(error))
            return
        }
        
        guard totalSalaries + sitter.salary <= budget else {
            completion(.failure(ZooError.notEnoughBudget))
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
    
    init(waterLimit:Double, budget: Double , animals: [Animal], sitters: [Sitter]){
        self.waterLimit = waterLimit - animals.reduce(0) { $0 + $1.waterConsumption }
        self.budget = budget
        self.animals = animals
        self.sitters = sitters
    }
}

//All the scenarios I can see have been tried below.

//Create animal instances.
var dog1: Animal = Dog(name: "Karabas",waterConsumption: 6)
var dog2: Animal = Dog(name: "Zeytin", waterConsumption: 6)
var dog3: Animal = Dog(name: "Pasa", waterConsumption: 6)
var cat1: Animal = Cat(name: "Boncuk",waterConsumption: 5)
var cat2: Animal = Cat(name: "Duman", waterConsumption: 5)
var cat3: Animal = Cat(name: "Limon", waterConsumption: 5)

//Create a sitter instance and assign some animals in constructor.
var sit1 = SitterImp(name: "Ogun", animals: [dog1,dog2])


//Create sitter instances and assign some animals after initialization using add function.
var sit2 = SitterImp(name: "Oguz" ,animals: [])
var sit3 = SitterImp(name: "Osman" ,animals: [])

sit2.assign(animal: &cat1) { result in
    switch result {
    case .success(let animal):
        print("\(sit2.name!) appointed to \(animal.name!) as sitter.")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

sit2.assign(animal: &cat2) { result in
    switch result {
    case .success(let animal):
        print("\(sit2.name!) appointed to \(animal.name!) as sitter.")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//If we try an animal that already has a sitter
sit2.assign(animal: &cat2) { result in
    switch result {
    case .success(let animal):
        print("\(sit2.name!) appointed to \(animal.name!) as sitter.")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

sit3.assign(animal: &cat3) { result in
    switch result {
    case .success(let animal):
        print("\(sit2.name!) appointed to \(animal.name!) as sitter.")
    case .failure(let error):
        print(error.localizedDescription)
    }
}
cat1.speak()
dog1.speak()


// Create zoo instance, add dog1 and sit1 in constructor.
var zoo = ZooImpl(waterLimit: 15, budget: 3_000, animals: [dog1], sitters: [sit1])

//We can add add animal and sitter after zoo initialization using add function
zoo.add(animal: dog2) { result in
    switch result {
    case .success(let animal):
        print("\(animal.name!) added to zoo!!")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

zoo.add(sitter: sit2) { result in
    switch result {
    case .success(let sitter):
        print("\(sitter.name!) added to zoo!!")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//If we try to add same sitter again.
zoo.add(sitter: sit2) { result in
    switch result {
    case .success(let sitter):
        print("\(sitter.name!) added to zoo!!")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

// If we don't have water to add more animals and we try.
zoo.add(animal: cat1) { result in
    switch result {
    case .success(let animal):
        print("\(animal.name!) added to zoo!!")
    case .failure(let error):
        print(error.localizedDescription)
    }
}
// If we don't have enough budget to add more sitter.
zoo.add(sitter: sit3) { result in
    switch result {
    case .success(let sitter):
        print("\(sitter.name!) added to zoo!!")
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
