import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _databaseHelper = DatabaseHelper._();
  DatabaseHelper._();
  late Database db;
  factory DatabaseHelper() {
    return _databaseHelper;
  }
  Future<void> initDB() async {
    String path = await getDatabasesPath();
    print('Database path: $path');
    db = await openDatabase(
      join(path, 'cooking.db'),
      onCreate: (database, version) async {
        print('Creating tables...');
        await database.execute("""CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL,
          password TEXT NOT NULL,
          bio TEXT NOT NULL
        )
        """);
        await database.execute("""CREATE TABLE recipes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          filter1 TEXT NOT NULL,
          filter2 TEXT NOT NULL,
          filter3 TEXT NOT NULL,
          servings INTEGER NOT NULL,
          prepTime INTEGER NOT NULL,
          cookTime INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id) on DELETE CASCADE
        )
        """);
        await database.execute("""CREATE TABLE ingredients(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          recipe_id INTEGER NOT NULL,
          ingredient TEXT NOT NULL,
          amount TEXT NOT NULL,
          FOREIGN KEY (recipe_id) REFERENCES recipes(id) on DELETE CASCADE
        )
        """);
        await database.execute("""CREATE TABLE stages(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          recipe_id INTEGER NOT NULL,
          num INTEGER NOT NULL,
          info TEXT NOT NULL,
          FOREIGN KEY (recipe_id) REFERENCES recipes(id) on DELETE CASCADE
        )
        """);
        await database.execute("""CREATE TABLE user_saved_recipes(
          user_id INTEGER,
          recipe_id INTEGER,  
          PRIMARY KEY (user_id, recipe_id),
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
        )
        """);
        await database.execute("""CREATE TABLE user_cart(
          user_id INTEGER,
          ingredient_id INTEGER,
          has_ingredient BOOL DEFAULT 0,
          PRIMARY KEY (user_id, ingredient_id),
          FOREIGN KEY (user_id) REFERENCES users(id) on DELETE CASCADE,
          FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) on DELETE CASCADE
        )
        """);
        await database.execute('''
          INSERT INTO users (username, password, bio)
          VALUES 
            ('girly','123','get cool'),
            ('pooper','123','get cool');
        ''');
        await database.execute('''
          INSERT INTO recipes (user_id, title, description, filter1, filter2, filter3, servings, prepTime, cookTime)
          VALUES 
            (1, 'Spaghetti Bolognese', 'Classic Italian dish with meat sauce', 'Italian', 'Pasta', 'Meat', 4, 20, 30),
            (2, 'Chicken Alfredo', 'Creamy Alfredo sauce with grilled chicken', 'Italian', 'Chicken', 'Creamy', 3, 15, 25),
            (1, 'Vegetarian Stir-Fry', 'Healthy stir-fried vegetables with tofu', 'Asian', 'Vegetarian', 'Stir-Fry', 2, 25, 20);
        ''');
        await database.execute('''
          INSERT INTO ingredients (recipe_id, ingredient, amount)
          VALUES
            (1, 'Pasta', '3 cups'),
            (1, 'Tomatos', '6'),
            (1, 'Butter', '4 tbs'),
            (2, 'Chicken breast', '3'),
            (3, 'Red bell pepper', '3');
        ''');
        await database.execute('''
          INSERT INTO stages (recipe_id, num, info)
          VALUES
            (1, 1, 'Boil the water'),
            (1, 2, 'Put the pasta'),
            (1, 3, 'Combine pasta and sauce'),
            (1, 4, 'Serve and enjoy hot!'),
            (2, 1, 'Assemble'),
            (3, 1, 'Assemble');
        ''');
      },
      version: 1,
    );
    print('Database initialized successfully');
  }
  Future<int> insertUser(User user) async {
    int result = await db.insert('users', user.toMap());
    return result;
  }

  Future<int> updateBio(int userId, String newBio) async {
    return await db.update(
      'users',
      {'bio': newBio},
      where: "id = ?",
      whereArgs: [userId],
    );
  }

  Future<List<User>> retrieveUsers() async {
    final List<Map<String, Object?>> queryResult = await db.query('users');
    print('All Users:');
    queryResult.forEach((userMap) {
      queryResult.forEach((userMap) {
        print('ID: ${userMap['id']}');
        print('Username: ${userMap['username']}');
        print('Password: ${userMap['password']}');
        print('Bio: ${userMap['bio']}');
        print('\n');
      });
    });

    return queryResult.map((e) => User.fromMap(e)).toList();
  }

  Future<User?> getUserByID(int id) async {
    var result = await db.query(
      'users', 
      where: "id = ?",
      whereArgs: [id]
    ); 
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<User?> getUserByUsername(String username) async {
    var result = await db.query(
      'users', 
      where: "username = ?",
      whereArgs: [username]
    ); 
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<int> insertRecipe(Recipe recipe) async {
    return await db.transaction((txn) async {
      int recipeId = await txn.insert('recipes', recipe.toMap());
      return recipeId;
    });
  }

  Future<List<Recipe>> retrieveRecipes() async {
    final List<Map<String, Object?>> queryResult = await db.query('recipes');
    print('All Recipes:');
    queryResult.forEach((recipeMap) {
      queryResult.forEach((recipeMap) {
        print('Title: ${recipeMap['title']}');
        print('Description: ${recipeMap['description']}');
        print('\n');
      });
    });

    return queryResult.map((e) => Recipe.fromMap(e)).toList();
  }
  
  Future<Recipe?> getRecipeByID(int id) async {
    var result = await db.query(
      'recipes', 
      where: "id = ?",
      whereArgs: [id]
    ); 
    if (result.isNotEmpty) {
      return Recipe.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<Recipe?> getRecipeByTitle(String title) async {
    var result = await db.query(
      'recipes', 
      where: "title = ?",
      whereArgs: [title]
    ); 
    if (result.isNotEmpty) {
      return Recipe.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<int> saveRecipeForUser(int userId, int recipeId) async {
    return await db.insert('user_saved_recipes', {'user_id': userId, 'recipe_id': recipeId},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeRecipeForUser(int userId, int recipeId) async {
    await db.delete(
      'user_saved_recipes',
      where: "user_id = ? AND recipe_id = ?",
      whereArgs: [userId, recipeId],
    );
  }
  
  Future<List<Recipe>> getSavedRecipesForUser(int userId) async {
    final List<Map<String, dynamic>> queryResult = await db.query('user_saved_recipes',
        where: 'user_id = ?',
        whereArgs: [userId]);
    
    final List<int> recipeIds = queryResult.map((row) => row['recipe_id'] as int).toList();

    final List<Map<String, dynamic>> recipesResult = await db.query('recipes',
        where: 'id IN (${List.filled(recipeIds.length, '?').join(', ')})',
        whereArgs: recipeIds);

    return recipesResult.map((recipeMap) => Recipe.fromMap(recipeMap)).toList();
  }

  Future<List<Recipe>> getRecipesByUser(int userId) async {
    final List<Map<String, dynamic>> queryResult = await db.query('recipes',
        where: 'user_id = ?',
        whereArgs: [userId]);

    return queryResult.map((recipeMap) => Recipe.fromMap(recipeMap)).toList();
  }

  Future<int> insertIngredient(Ingredient ingredient) async {
    return await db.transaction((txn) async {
      int ingredientId = await txn.insert('ingredients', ingredient.toMap());
      return ingredientId;
    });
  }
  
  Future<List<Ingredient>> getIngredientsForRecipe(int recipeId) async {
    final List<Map<String, dynamic>> queryResult = await db.query('ingredients',
        where: 'recipe_id = ?',
        whereArgs: [recipeId]);

    return queryResult.map((ingredientMap) => Ingredient.fromMap(ingredientMap)).toList();
  }

  Future<bool> isIngredientInCart(int userId, int ingredientId) async {
    final List<Map<String, dynamic>> queryResult = await db.query('user_cart',
        where: 'user_id = ? AND ingredient_id = ?',
        whereArgs: [userId, ingredientId]);

    return queryResult.isNotEmpty;
  }

  Future<Ingredient?> getIngredientByNameAndRecipeId(String ingredientName, int recipeId) async {
    var result = await db.query(
      'ingredients',
      where: "ingredient = ? AND recipe_id = ?",
      whereArgs: [ingredientName, recipeId],
    );
    return Ingredient.fromMap(result.first);
  }

  Future<int> insertStep(Stage stage) async {
    return await db.transaction((txn) async {
      int stageId = await txn.insert('stages', stage.toMap());
      return stageId;
    });
  }

  Future<List<Stage>> getStagesForRecipe(int recipeId) async {
    final List<Map<String, dynamic>> queryResult = await db.query('stages',
        where: 'recipe_id = ?',
        whereArgs: [recipeId]);

    return queryResult.map((stageMap) => Stage.fromMap(stageMap)).toList();
  }

  Future<int> addToCart(int userId, int ingredientId) async {
    return await db.insert('user_cart', {'user_id': userId, 'ingredient_id': ingredientId},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFromCart(int userId, int ingredientId) async {
    await db.delete(
      'user_cart',
      where: "user_id = ? AND ingredient_id = ?",
      whereArgs: [userId, ingredientId],
    );
  }

  Future<bool?> getIngredientStatus(int userId, int ingredientId) async {
    final List<Map<String, dynamic>> queryResult = await db.query(
      'user_cart',
      columns: ['has_ingredient'],
      where: 'user_id = ? AND ingredient_id = ?',
      whereArgs: [userId, ingredientId],
    );
    return queryResult.first['has_ingredient'] == 1;
  }

  Future<List<bool>> getIngredientsStatusInCart(int userId) async {
    final List<Map<String, dynamic>> queryResult = await db.query(
      'user_cart',
      columns: ['has_ingredient'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return queryResult.map((row) => row['has_ingredient'] == 1).toList();
  }

  Future<void> updateIngredientStatus(int userId, int ingredientId, bool hasIngredient) async {
    await db.update(
      'user_cart',
      {'has_ingredient': hasIngredient ? 1 : 0},
      where: "user_id = ? AND ingredient_id = ?",
      whereArgs: [userId, ingredientId],
    );
  }

  Future<List<Ingredient>> getIngredientsInCart(int userId) async {
    final List<Map<String, dynamic>> queryResult = await db.query('user_cart',
        where: 'user_id = ?',
        whereArgs: [userId]);

    final List<int> ingredientIds = queryResult.map((row) => row['ingredient_id'] as int).toList();

    final List<Map<String, dynamic>> ingredientsResult = await db.query('ingredients',
        where: 'id IN (${List.filled(ingredientIds.length, '?').join(', ')})',
        whereArgs: ingredientIds);

    return ingredientsResult.map((ingredientMap) => Ingredient.fromMap(ingredientMap)).toList();
  }
}



class User {
  int? id;
  String username;
  String password;
  String bio;

  User({this.id, required this.username, required this.password, required this.bio});

  User.fromMap(Map<String, dynamic> res)
      : id = res["id"],
        username = res["username"],
        password = res["password"],
        bio = res["bio"];        

  Map<String, Object?> toMap() => {'id': id, 'username': username, 'password': password, 'bio': bio};
}

class Recipe {
  int? id;
  int user_id;
  String title;
  String description;
  String filter1;
  String filter2;
  String filter3;
  int servings;
  int prepTime;
  int cookTime;

  Recipe({this.id, required this.user_id, required this.title, required this.description, required this.filter1, required this.filter2, required this.filter3, required this.servings, required this.prepTime, required this.cookTime});

  Recipe.fromMap(Map<String, dynamic> res)
      : id = res["id"],
        user_id = res["user_id"],
        title = res["title"],
        description = res["description"],
        filter1 = res["filter1"],
        filter2 = res["filter2"],
        filter3 = res["filter3"],
        servings = res["servings"],
        prepTime = res["prepTime"],
        cookTime = res["cookTime"];
  
  Map<String, Object?> toMap() {
    return {'id': id, 'user_id': user_id, 'title': title, 'description': description, 'filter1': filter1, 'filter2': filter2, 'filter3': filter3, 'servings': servings, 'prepTime': prepTime, 'cookTime': cookTime};
  }
}

class Ingredient {
  int? id;
  int recipe_id;
  String ingredient;
  String amount;

  Ingredient({this.id, required this.recipe_id,required this.ingredient, required this.amount});

  Ingredient.fromMap(Map<String, dynamic> res)
      : id = res["id"],
        recipe_id = res["recipe_id"],
        ingredient = res["ingredient"],
        amount = res["amount"];
  
  Map<String, Object?> toMap() {
    return {'id': id, 'recipe_id': recipe_id, 'ingredient': ingredient, 'amount': amount};
  }
}

class Stage {
  int? id;
  int recipe_id;
  int num;
  String info;

  Stage({this.id, required this.recipe_id, required this.num, required this.info});

  Stage.fromMap(Map<String, dynamic> res)
      : id = res["id"],
        recipe_id = res["recipe_id"],
        num = res["num"],
        info = res["info"];
  
  Map<String, Object?> toMap() {
    return {'id': id, 'recipe_id': recipe_id,'num': num, 'info': info};
  }
}