# Validation
Validation is a type which is similar to result but it have some extra functionality like accumlating validation error.

# Example 
Let's say we have a struct call RegisterUserRequest. We have some values which may be coming from forms or somewhere else, we have to validate these values before we construct RegisterUserRequest. 

```swift
struct RegisterUserRequest {
    let phone: Int
    let email: String
}
```

So we write some validation function for phone and email. 

```swift
func validateNumber(_ input: String?) -> Validation<Int, String> {
    guard let ip = input, let num = Int(ip) else {
        return .invalid("Input is not number.")
    }
    return .valid(num)
}

func validatePhoneNumber(_ input: String?) -> Validation<Int, String> {
    if input?.count ?? 0 > 7 {
        return .valid(Int(input!)!)
    } else {
        return .invalid("Invalid Phone No")
    }
}

func validateEmail(_ input: String?) -> Validation<String, String> {
    guard input?.contains("@") == true else {
        return .invalid("Input is not email")
    }
    return .valid(input!)
}
```
So with these functions, let's wire them to get RegisterUserRequest. 
```swift
let phoneNoValidation = validatePhoneNumber("")
    
let emailValidation = validateEmail("user@mail.com")

let registerUser = .pure(curry(RegisterUserRequest.init))
    <*> phoneNoValidation
    <*> emailValidation

```
If we print out the registerUser, it will log `invalid("Invalid Phone No")` in the console.

The message seems a little bit irrelevant. You provided the empty string for phone no, so the error message you want may be `Required` or some kinda message. So you may go and tweak `phoneNoValidation` function like below.

```swift
func validatePhoneNumber(_ input: String?) -> Validation<Int, String> {
    if input?.count ?? 0 > 7 {
        return .valid(Int(input!)!)
    } else if input?.count == 0 {
        return .invalid("Required")
    }
    else {
        return .invalid("Invalid Phone No")
    }
}
```

Yeah it will work as you expected now but let's say we want it too for `emailValidation`. Then we may have to go and tweak that function again. Instead we create another function that only focus on required validation. 

```swift
func validateNonEmpty(_ input: String?) -> Validation<String, String> {
    guard input?.isEmpty == false else {
        return .invalid("Required")
    }
    return .valid(input!)
}
```

Now the codes become like this 

```swift
let phoneNoValidation = validateNonEmpty("")
    .flatMap(validatePhoneNumber)
    
let emailValidation1 = validateNonEmpty("")
    .flatMap(validateEmail)
```

And it will print `Required Required` in the console. So by creat another function that only foucus on one job (single responsibility), we gain reusablity, readibility, composibiltity and testablity. 

And also let's say you have a use case where a values need to validated by multiple rules, you can continue composing these using `flatMap` without losing the readibility.

If you feels unfamilier with using `<*>` you can instead use `zip` `zip(with:)`.

```swift
let registerUser = zip(with: RegisterUserRequest.init)(
    phoneNoValidation,
    emailValidation
)
```
# Credit
[Applicative and Swift by Stephen Celis ](https://www.youtube.com/watch?v=Awva79gjoHY&t=1681s)

[Pointfree.co](https://www.pointfree.co)
