import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cooking_app/DatabaseHelper.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
} 

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: <RouteBase> [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage()
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpPage()
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      routes: <RouteBase> [
        GoRoute(
          parentNavigatorKey: _shellNavigatorKey,
          path: '/feed',
          builder: (context, state) => const FeedPage()
        ),
        GoRoute(
          parentNavigatorKey: _shellNavigatorKey,
          path: '/recipeBook',
          builder: (context, state) => const RecipeBookPage(),
        ),
        GoRoute(
          parentNavigatorKey: _shellNavigatorKey,
          path: '/cart',
          builder: (context, state) => const CartPage(),
        ),
        GoRoute(
          parentNavigatorKey: _shellNavigatorKey,
          path: '/profile',
          builder: (context, state) => const ProfilePage()
        ),
        GoRoute(
          path: '/specificRecipe',
          builder: (context, state) => const SpecificRecipePage(),
        ),
        GoRoute(
          path: '/createRecipe',
          builder: (context, state) =>const CreateRecipePage()
        )
      ],
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      }
    )
  ]
);

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({super.key, required this.child});

  final Widget child;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

int _currentIndex = 3;

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {

  static const List<MyCustomBottomNavBarItem> tabs = [
    MyCustomBottomNavBarItem(
      icon: Icon(Icons.feed),
      label: 'Feed',
      initialLocation: '/feed',
    ),
    MyCustomBottomNavBarItem(
      icon: Icon(Icons.book),
      label: 'Recipe Book',
      initialLocation: '/recipeBook',
    ),
    MyCustomBottomNavBarItem(
      icon: Icon(Icons.shopping_bag),
      label: 'Cart',
      initialLocation: '/cart',
    ),
    MyCustomBottomNavBarItem(
      icon: Icon(Icons.person),
      label: 'Me',
      initialLocation: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: widget.child),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: color3,
        selectedItemColor: color1,
        selectedFontSize: 12,
        unselectedItemColor: color4,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (int index) {
          _goOtherTab(context, index);
        },
        currentIndex: _currentIndex,
        items: tabs,
      ),
    );
  }

  void _goOtherTab(BuildContext context, int index) {
    if (index == _currentIndex) return;
    GoRouter router = GoRouter.of(context);
    String location = tabs[index].initialLocation;
    if (index == 3) {
      router.push(location);
    }

    setState(() {
      _currentIndex = index;
      router.go(location);
    });
  }
}

class MyCustomBottomNavBarItem extends BottomNavigationBarItem {
  final String initialLocation;

  const MyCustomBottomNavBarItem(
      {required this.initialLocation,
      required Widget icon,
      String? label,
      Widget? activeIcon})
      : super(icon: icon, label: label, activeIcon: activeIcon ?? icon);
}


Color color1 = const Color.fromARGB(255, 241, 241, 241);
Color color2 = const Color.fromARGB(255, 173, 173, 173);
Color color3 = const Color.fromARGB(255, 104, 104, 104);
Color color4 = const Color.fromARGB(255, 62, 60, 60);
Color color5 = const Color.fromARGB(255, 29, 28, 28);

fontSize4(context) => MediaQuery.of(context).size.width > MediaQuery.of(context).size.height? 
  MediaQuery.of(context).size.height * 0.08 : MediaQuery.of(context).size.width * 0.08;

fontSize3(context) => MediaQuery.of(context).size.width > MediaQuery.of(context).size.height? 
  MediaQuery.of(context).size.height * 0.05 : MediaQuery.of(context).size.width * 0.05;

fontSize2(context) => MediaQuery.of(context).size.width > MediaQuery.of(context).size.height? 
  MediaQuery.of(context).size.height * 0.03 : MediaQuery.of(context).size.width * 0.04;

fontSize1(context) => MediaQuery.of(context).size.width > MediaQuery.of(context).size.height? 
  MediaQuery.of(context).size.height * 0.025 : MediaQuery.of(context).size.width * 0.03;

late DatabaseHelper dbHelper;
late User _user;
late List<Recipe> _userSavedRecipes;
late List<Recipe> _userCreatedRecipes;
late List<Ingredient> _userCart;
late Recipe _recipe;
late List<Ingredient> _recipeIngredients;
late List<Stage> _recipeStages;
late List<bool> _cartStatus;
bool _recipeStarted = false;
late Stage _stage;

_showMessage(context, content) {
  showDialog(
    context: context, 
    builder: (context) {
      return AlertDialog(
        backgroundColor: color4,
        content: Text(
          content,
          style: TextStyle(
            color: color2,
            fontSize: fontSize3(context),
            fontWeight: FontWeight.w600
          )
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  return states.contains(MaterialState.pressed) ||
                        states.contains(MaterialState.hovered)
                    ? color2
                    : color3;
                },
              ),
            ),
            child: Text(
              'OK',
              style: TextStyle(
                color: color1,
                fontSize: fontSize2(context),
                fontWeight: FontWeight.w800
              )
            )
          )
        ]
      );
    }
  );
}

_recipeListView (Future <List<Recipe>> list) {
  return FutureBuilder(
    future: list,
    builder: (BuildContext context, AsyncSnapshot<List<Recipe>> snapshot) {
      if (snapshot.hasData) {
        List<Recipe> recipes = snapshot.data!;
        return ListView.separated(
          shrinkWrap: true,
          itemCount: snapshot.data!.length,
          itemBuilder: (context, position) => GestureDetector(
              onTap: () async {
                Recipe? selectedRecipe = await dbHelper.getRecipeByID(recipes[position].id!);
                List<Ingredient> selectedRecipeIngredients = await dbHelper.getIngredientsForRecipe(recipes[position].id!);
                List<Stage> selectedRecipeStages = await dbHelper.getStagesForRecipe(recipes[position].id!);
                if(selectedRecipe != null) {                  
                  _recipe = selectedRecipe;
                  _recipeIngredients = selectedRecipeIngredients;
                  _recipeStages = selectedRecipeStages;
                  _router.go('/specificRecipe');
                }
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: color2,
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: color3,
                              borderRadius: BorderRadius.circular(5)
                            ),
                            width: MediaQuery.of(context).size.width * 0.65,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Center(
                                child: Text(
                                snapshot.data![position].title,
                                  style: TextStyle(
                                    color: color1,
                                    fontWeight: FontWeight.w700,
                                    fontSize: fontSize3(context)
                                  )
                                )
                              )
                            )
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.all(5)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: color4,
                              borderRadius: BorderRadius.circular(5)
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(
                                snapshot.data![position].filter1,
                                style: TextStyle(
                                  color: color2,
                                  fontWeight: FontWeight.w800,
                                  fontSize: fontSize2(context)
                                ),
                              )
                            ),
                          ),
                          const Padding(padding: EdgeInsets.all(5)),
                          Container(
                            decoration: BoxDecoration(
                              color: color4,
                              borderRadius: BorderRadius.circular(5)
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(
                                snapshot.data![position].filter2,
                                style: TextStyle(
                                  color: color2,
                                  fontWeight: FontWeight.w800,
                                  fontSize: fontSize2(context)
                                ),
                              )
                            ),
                          ),
                          const Padding(padding: EdgeInsets.all(5)),
                          Container(
                            decoration: BoxDecoration(
                              color: color4,
                              borderRadius: BorderRadius.circular(5)
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(
                                snapshot.data![position].filter3,
                                style: TextStyle(
                                  color: color2,
                                  fontWeight: FontWeight.w800,
                                  fontSize: fontSize2(context)
                                ),
                              )
                            ),
                          )
                        ],
                      ),
                      const Padding(padding: EdgeInsets.all(5)),
                      FutureBuilder(
                        future: dbHelper.getUserByID(snapshot.data![position].user_id),
                        builder: (BuildContext context, AsyncSnapshot<User?> userSnapshot) {
                          if (userSnapshot.hasData) {
                            return Text(
                              userSnapshot.data!.username,
                              style: TextStyle(
                                color: color4,
                                fontWeight: FontWeight.w900,
                                fontSize: fontSize2(context),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                      ),
                      const Padding(padding: EdgeInsets.all(5)),
                      Text(
                        snapshot.data![position].description,
                        style: TextStyle(
                          color: color4,
                          fontSize: fontSize2(context)
                        ),
                      )
                    ],
                  ),
                ),
              )
            ),
          separatorBuilder: (context, index) => const Padding(padding: EdgeInsets.all(10)),
        );
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    }
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(context) {
    return MaterialApp.router(
      routerConfig:  _router,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    dbHelper.initDB().whenComplete(() async {
      setState(() {});
    });
  }

  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: color2,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color3,
                  borderRadius: const BorderRadius.all(Radius.circular(10))
                ),
                width: MediaQuery.of(context).size.width * 0.6,
                height: MediaQuery.of(context).size.height * 0.08,
                child: Center(
                  child:Text(
                    'COOKNOOK',
                    style: TextStyle(
                      color: color1,
                      fontSize: fontSize4(context),
                      fontWeight: FontWeight.w800
                    ),
                  )
                )
              ),
              
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10))
                ),
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.08,
                child: Center(
                  child:Text(
                    'WELCOME',
                    style: TextStyle(
                      color: color4,
                      fontSize: fontSize3(context),
                      fontWeight: FontWeight.w800
                    ),
                  )
                )
              ),
              
              Container(
                decoration: BoxDecoration(
                  color: color1,
                  borderRadius: const BorderRadius.all(Radius.circular(10))
                ),
                width: MediaQuery.of(context).size.width * 0.8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Column(
                    children: [
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(
                            color: color3
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color3),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color2),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: fontSize2(context),
                          color: color3,
                          fontWeight: FontWeight.w700
                        ),
                        cursorColor: color5,
                      ),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        obscuringCharacter: '•',
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: color3
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color3),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color2),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: fontSize2(context),
                          color: color3,
                          fontWeight: FontWeight.w700
                        ),
                        cursorColor: color5,
                      ),
                      const Padding(padding: EdgeInsets.all(10)),
                      OutlinedButton(
                        onPressed: () async {
                          if(usernameController.text.isEmpty || passwordController.text.isEmpty) {
                            _showMessage(context, 'Please fill out all fields.');
                            return;
                          }
                          User? loggedInUser = await dbHelper.getUserByUsername(usernameController.text);
                          if(loggedInUser == null) {
                            _showMessage(context, 'This Username does not exist.');
                          } else if (loggedInUser.password != passwordController.text) {
                            _showMessage(context, 'Incorrect Password.');
                          } else {
                            _user = loggedInUser;
                            _userSavedRecipes = await dbHelper.getSavedRecipesForUser(_user.id!);
                            _userCreatedRecipes = await dbHelper.getRecipesByUser(_user.id!);
                            _userCart = await dbHelper.getIngredientsInCart(_user.id!);
                            _router.go('/profile');
                            Future.delayed(const Duration(milliseconds: 100), () {
                              _showMessage(context, 'You successfully logged in!');
                            });
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              return states.contains(MaterialState.pressed) ||
                                      states.contains(MaterialState.hovered)
                                  ? color2
                                  : color3;
                            },
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(
                            'LOGIN',
                            style: TextStyle(
                              color: color1,
                              fontSize: fontSize3(context),
                              fontWeight: FontWeight.w700
                            )
                          )
                        )
                      ),                      
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _router.go('/signup');
                          });
                        },
                        child: Text(
                          'Need an account? SIGN UP',
                          style: TextStyle(
                            color: color3,
                            fontSize: fontSize1(context)
                          )                
                        ),
                      )
                    ],
                  )
                )
              )
            ],
          ),
        )
      )
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    dbHelper.initDB().whenComplete(() async {
      setState(() {});
    });
  }
  
  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: color2,
      appBar: AppBar(
        backgroundColor: color2,
        shadowColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            _router.go('/login');
          },
          icon: Icon(
            Icons.arrow_back,
            color: color1
            )
        )
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color3,
                  borderRadius: const BorderRadius.all(Radius.circular(10))
                ),
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.1,
                child: Center(
                  child: Text(
                    'SIGN UP',
                    style: TextStyle(
                      color: color1,
                      fontSize: fontSize4(context),
                      fontWeight: FontWeight.w800
                    ),
                  )
                )
              ),
              const Padding(padding: EdgeInsets.all(10)),
              Container(
                decoration: BoxDecoration(
                  color: color1,
                  borderRadius: const BorderRadius.all(Radius.circular(10))
                ),
                width: MediaQuery.of(context).size.width * 0.8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Column(
                    children: [
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(
                            color: color3
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color3),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color2),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: fontSize2(context),
                          color: color3,
                          fontWeight: FontWeight.w700
                        ),
                        cursorColor: color5,
                      ),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        obscuringCharacter: '•',
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: color3
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color3),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color2),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: fontSize2(context),
                          color: color3,
                          fontWeight: FontWeight.w700
                        ),
                        cursorColor: color5,
                      ),
                      TextField(
                        controller: confirmController,
                        obscureText: true,
                        obscuringCharacter: '•',
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          labelStyle: TextStyle(
                            color: color3
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color3),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color2),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: fontSize2(context),
                          color: color3,
                          fontWeight: FontWeight.w700
                        ),
                        cursorColor: color5,
                      ),
                      const Padding(padding: EdgeInsets.all(10)),
                      OutlinedButton(
                        onPressed: () async {
                            if(usernameController.text.isEmpty || passwordController.text.isEmpty || confirmController.text.isEmpty) {
                                _showMessage(context, 'Please fill out all fields.');
                                return;
                              }
                            if(confirmController.text != passwordController.text) {
                              _showMessage(context, 'Passwords must match.');
                              return;
                            }
                            if(await dbHelper.getUserByUsername(usernameController.text) != null) {
                              _showMessage(context, 'This Username is already associated with an account.');
                              return;
                            }
                            _user = User(username: usernameController.text, password: passwordController.text, bio: 'No bio.');
                            addUser();
                            _router.go('/login');
                            Future.delayed(const Duration(milliseconds: 100), () {
                              _showMessage(context, 'Account successfully created!');
                            });
                            
                            dbHelper.retrieveUsers();
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              return states.contains(MaterialState.pressed) ||
                                      states.contains(MaterialState.hovered)
                                  ? color2
                                  : color3;
                            },
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              color: color1,
                              fontSize: fontSize3(context),
                              fontWeight: FontWeight.w700
                            )
                          )
                        )
                      ),
                    ],
                  )
                )
              )
            ],
          )
        )
      )
    );
  }
}

class SpecificRecipePage extends StatefulWidget {
  const SpecificRecipePage({super.key});

  @override
  State<SpecificRecipePage> createState() => _SpecificRecipePage();
}

class _SpecificRecipePage extends State<SpecificRecipePage> {

  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: color5,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(child: recipeWidget()),
          ),
        ],
      ),
    );
  }


  Widget recipeWidget() {
    return FutureBuilder(
      future: dbHelper.retrieveRecipes(),
      builder: (BuildContext context, AsyncSnapshot<List<Recipe>> snapshot) {
        if (snapshot.hasData) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: double.infinity,
            child: GestureDetector(
              onHorizontalDragEnd: (dragEndDetails) {
                final details = dragEndDetails.primaryVelocity;
                if(details != null && details > 3) {
                  _currentIndex == 0 ? _router.go('/feed') : _currentIndex == 1 ? _router.go('/recipeBook') : _currentIndex == 2? _router.go('/cart') : _router.go('/profile');
                }
              },
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: color4,
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            _recipe.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: color2,
                              fontSize: fontSize4(context),
                              fontWeight: FontWeight.w800
                            ),
                          )
                        )
                      ),
                      const Padding(padding: EdgeInsets.all(10)),
                      TextButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              return states.contains(MaterialState.pressed) ||
                                  states.contains(MaterialState.hovered)
                              ? color1
                              : color2;
                            },
                          ),
                        ),
                        onPressed: () async {
                          if (_userSavedRecipes.any((savedRecipe) => savedRecipe.id == _recipe.id)) {
                            await dbHelper.removeRecipeForUser(_user.id!, _recipe.id!);
                            _showMessage(context, 'Recipe removed!');
                          } else {
                            await dbHelper.saveRecipeForUser(_user.id!, _recipe.id!);
                            _showMessage(context, 'Recipe saved!');
                          }
                          _userSavedRecipes = await dbHelper.getSavedRecipesForUser(_user.id!);
                          setState(() {});
                        },
                        child: Text(
                          _userSavedRecipes.any((savedRecipe) => savedRecipe.id == _recipe.id) ?
                          'Remove from Recipe Book' : 'Add to Recipe Book',
                          style: TextStyle(
                            color: color4,
                            fontSize: fontSize2(context),
                            fontWeight: FontWeight.w800
                          ),
                        )
                      ),
                      const Padding(padding: EdgeInsets.all(10)),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: color2,
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              OutlinedButton(
                                onPressed: () {

                                },
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                                      return states.contains(MaterialState.pressed) ||
                                            states.contains(MaterialState.hovered)
                                        ? color1
                                        : color3;
                                    },
                                  ),
                                ),
                                child:
                                FutureBuilder(
                                  future: dbHelper.getUserByID(_recipe.user_id),
                                  builder: (BuildContext context, AsyncSnapshot<User?> userSnapshot) {
                                    if (userSnapshot.hasData) {
                                      return Text(
                                        'Created by: ${userSnapshot.data!.username}',
                                        style: TextStyle(
                                          color: color2,
                                          fontSize: fontSize2(context),
                                          fontWeight: FontWeight.w800
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }
                                ),
                              ),
                              const Padding(padding: EdgeInsets.all(5)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.25,
                                    decoration: BoxDecoration(
                                      color: color3,
                                      borderRadius: BorderRadius.circular(5)
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Center(
                                        child: Text(
                                          _recipe.filter1,
                                          style: TextStyle(
                                            color: color1,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      )
                                    )
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.25,
                                    decoration: BoxDecoration(
                                      color: color3,
                                      borderRadius: BorderRadius.circular(5)
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Center(
                                        child: Text(
                                          _recipe.filter2,
                                          style: TextStyle(
                                            color: color1,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      )
                                    )
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.25,
                                    decoration: BoxDecoration(
                                      color: color3,
                                      borderRadius: BorderRadius.circular(5)
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Center(
                                        child: Text(
                                          _recipe.filter3,
                                          style: TextStyle(
                                            color: color1,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      )
                                    )
                                  ),
                                ],
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    _recipe.description,
                                    style: TextStyle(
                                      color: color1,
                                      fontSize: fontSize3(context),
                                      fontWeight: FontWeight.w700
                                    ),
                                  ),
                                )
                              ),
                              const Padding(padding: EdgeInsets.all(5)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: color3,
                                      borderRadius: BorderRadius.circular(5)
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        '${_recipe.servings} Serving(s)',
                                        style: TextStyle(
                                          color: color1,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    )
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: color3,
                                      borderRadius: BorderRadius.circular(5)
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        'Prep: ${_recipe.prepTime}min',
                                        style: TextStyle(
                                          color: color1,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    )
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: color3,
                                      borderRadius: BorderRadius.circular(5)
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        'Cook: ${_recipe.cookTime}min',
                                        style: TextStyle(
                                          color: color1,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    )
                                  )
                                ],
                              )
                            ],
                          )
                        )
                      ),
                      const Padding(padding: EdgeInsets.all(10)),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: color4,
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: color4,
                                  borderRadius: BorderRadius.circular(5)
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    'Ingredients',
                                    style: TextStyle(
                                      color: color1,
                                      fontSize: fontSize3(context),
                                      fontWeight: FontWeight.w900
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _recipeIngredients.length,
                                  separatorBuilder: (context, index) => const Padding(padding: EdgeInsets.all(10)),
                                  itemBuilder: (context, index) => GestureDetector(
                                    onDoubleTap: () async{
                                      bool isIngredientInCart = await dbHelper.isIngredientInCart(_user.id!, _recipeIngredients[index].id!);
                                      if(!isIngredientInCart){
                                        setState(() {
                                          dbHelper.addToCart(_user.id!, _recipeIngredients[index].id!);
                                          _showMessage(context, 'Ingredient added to cart!');
                                        });
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: color3,
                                        borderRadius: BorderRadius.circular(5)
                                      ),  
                                      child: Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Row(
                                          children: [
                                            Text(
                                              '${_recipeIngredients[index].amount} ',
                                              style: TextStyle(
                                                color: color1,
                                                fontWeight: FontWeight.w900,
                                                fontSize: fontSize2(context)
                                              )
                                            ),
                                            Text(
                                              _recipeIngredients[index].ingredient,
                                              style: TextStyle(
                                                color: color1,
                                                fontWeight: FontWeight.w600,
                                                fontSize: fontSize2(context)
                                              ),
                                            ),
                                           // Icon( ? Icons.abc : Icons.access_alarm)
                                          ],
                                        )
                                      )
                                    )
                                  ) 
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.all(20)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _recipeStarted = true;
                            _showMessage(context, 'You are now in Cooking Mode.');
                            _stage = _recipeStages[0];
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              return states.contains(MaterialState.pressed) ||
                                  states.contains(MaterialState.hovered)
                                ? color2
                                : color1;
                            },
                          ),
                        ),
                        child: Text(
                          'START COOKING',
                          style: TextStyle(
                            color: color3,
                            fontSize: fontSize3(context),
                            fontWeight: FontWeight.w900
                          ),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.all(20)),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: color4,
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: color4,
                                  borderRadius: BorderRadius.circular(5)
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    'Instructions',
                                    style: TextStyle(
                                      color: color1,
                                      fontSize: fontSize3(context),
                                      fontWeight: FontWeight.w900
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _recipeStages.length,
                                  separatorBuilder: (context, index) => const Padding(padding: EdgeInsets.all(10)),
                                  itemBuilder: (context, index) => GestureDetector(
                                    onTap:() {
                                      setState(() {
                                        if(_stage.num == _recipeStages.length) {
                                          _recipeStarted = false;
                                          _showMessage(context, 'Bon Appétit!');
                                        } else {
                                          _stage = _recipeStages[_stage.num];
                                        }
                                      });                                    
                                    },
                                    onHorizontalDragEnd: (details) {
                                      final delta = details.primaryVelocity;
                                      if(delta != null && delta < 0 && _stage.num != 1) {
                                        setState(() {
                                          _stage = _recipeStages[_stage.num - 2];
                                        });
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: !_recipeStarted ? color3 : _stage.num -1 == index ? color2 : color4,
                                        borderRadius: BorderRadius.circular(5)
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                _recipeStages[index].info,
                                                style: TextStyle(
                                                  color: !_recipeStarted ? color1 : _stage.num -1 == index ? color4 : color5,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: fontSize2(context)
                                                ),
                                              ),
                                            )
                                          ],
                                        )
                                      )
                                    ) 
                                  )
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ),
            )
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  } 
}


class CreateRecipePage extends StatefulWidget {
  const CreateRecipePage({super.key});

  @override
  State<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  List<TextEditingController> controllers = [];
  List<List<TextEditingController>> _ingredientControllers = [[TextEditingController(), TextEditingController()]];
  List<TextEditingController> _stepsControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 8; i++) {
      controllers.add(TextEditingController());
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Recipe',
          style: TextStyle(
            fontSize: fontSize3(context),
            color: color1
          ),
        ),
        backgroundColor: color3,
      ),
      backgroundColor: color5,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: double.infinity,
        child: GestureDetector(
          onHorizontalDragEnd: (dragEndDetails) {
            final details = dragEndDetails.primaryVelocity;
            if(details != null && details > 3) {
              _router.go('/recipeBook');
            }
          },
          child: SingleChildScrollView(      
            padding: EdgeInsets.all(20),
            child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: color3,
                      borderRadius: const BorderRadius.all(Radius.circular(10))
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: TextField(
                        controller: controllers[0],
                        decoration: InputDecoration(
                          labelText: 'Title',
                          labelStyle: TextStyle(
                            color: color1
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color5),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: fontSize4(context),
                          color: color5,
                          fontWeight: FontWeight.w700
                        ),
                        cursorColor: color5,
                      )
                    )
                  ),
                  Padding(padding: EdgeInsets.all(20)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.26,
                        decoration: BoxDecoration(
                          color: color3,
                          borderRadius: const BorderRadius.all(Radius.circular(10))
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: TextField(
                            controller: controllers[1],
                            decoration: InputDecoration(
                              labelText: 'Filter 1',
                              labelStyle: TextStyle(
                                color: color1
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: color5),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: fontSize2(context),
                              color: color5,
                              fontWeight: FontWeight.w700
                            ),
                            cursorColor: color5,
                          )
                        )
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.26,
                        decoration: BoxDecoration(
                          color: color3,
                          borderRadius: const BorderRadius.all(Radius.circular(10))
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: TextField(
                            controller: controllers[2],
                            decoration: InputDecoration(
                              labelText: 'Filter 2',
                              labelStyle: TextStyle(
                                color: color1
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: color5),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: fontSize2(context),
                              color: color5,
                              fontWeight: FontWeight.w700
                            ),
                            cursorColor: color5,
                          )
                        )
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.26,
                        decoration: BoxDecoration(
                          color: color3,
                          borderRadius: const BorderRadius.all(Radius.circular(10))
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: TextField(
                            controller: controllers[3],
                            decoration: InputDecoration(
                              labelText: 'Filter 3',
                              labelStyle: TextStyle(
                                color: color1
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: color5),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: fontSize2(context),
                              color: color5,
                              fontWeight: FontWeight.w700
                            ),
                            cursorColor: color5,
                          )
                        )
                      ),
                    ],
                  ),
                  Padding(padding: EdgeInsets.all(20)),
                  Container(
                    decoration: BoxDecoration(
                      color: color3,
                      borderRadius: const BorderRadius.all(Radius.circular(10))
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: TextField(
                        maxLines: null,
                        controller: controllers[4],
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(
                            color: color1
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color5),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: fontSize3(context),
                          color: color5,
                          fontWeight: FontWeight.w700
                        ),
                        cursorColor: color5,
                      )    
                    )
                  ),
                  Padding(padding: EdgeInsets.all(20)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.26,
                        decoration: BoxDecoration(
                          color: color3,
                          borderRadius: const BorderRadius.all(Radius.circular(10))
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: TextField(
                            controller: controllers[5],
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              labelText: 'Servings',
                              labelStyle: TextStyle(
                                color: color1
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: color5),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: fontSize2(context),
                              color: color5,
                              fontWeight: FontWeight.w700
                            ),
                            cursorColor: color5,
                          )
                        )
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.26,
                        decoration: BoxDecoration(
                          color: color3,
                          borderRadius: const BorderRadius.all(Radius.circular(10))
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: TextField(
                            controller: controllers[6],
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              labelText: 'Prep Time',
                              hintText: 'Minutes',
                              labelStyle: TextStyle(
                                color: color1
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: color5),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: fontSize2(context),
                              color: color5,
                              fontWeight: FontWeight.w700
                            ),
                            cursorColor: color5,
                          )
                        )
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.26,
                        decoration: BoxDecoration(
                          color: color3,
                          borderRadius: const BorderRadius.all(Radius.circular(10))
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: TextField(
                            controller: controllers[7],
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              labelText: 'Cook Time',
                              hintText: 'Minutes',
                              labelStyle: TextStyle(
                                color: color1
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: color5),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: fontSize2(context),
                              color: color5,
                              fontWeight: FontWeight.w700
                            ),
                            cursorColor: color5,
                          )
                        )
                      ),
                    ],
                  ),
                  Padding(padding: EdgeInsets.all(20)),
                  Container(                  
                    decoration: BoxDecoration(
                      color: color3,
                      borderRadius: const BorderRadius.all(Radius.circular(10))
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Ingredients',
                        style: TextStyle(
                          fontSize: fontSize3(context),
                          fontWeight: FontWeight.w700,
                          color: color1
                        ),
                      )
                    )
                  ),
                  Padding(padding: EdgeInsets.all(20)),
                  Container(
                    decoration: BoxDecoration(
                      color: color3,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _ingredientControllers.length,
                            itemBuilder: (context, index) => Dismissible(
                              direction: DismissDirection.endToStart,
                              key: UniqueKey(),
                              background: Container(
                                decoration: BoxDecoration(
                                  color: color4,
                                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                                ),
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: Icon(
                                  Icons.delete_forever,
                                  color: color1,
                                ),
                              ),
                              confirmDismiss: (DismissDirection direction) {
                                return Future<bool?>.value(_ingredientControllers.length > 1);
                              },
                              onDismissed: (DismissDirection direction) {
                                if (_ingredientControllers.length > 1) {
                                  setState(() {
                                    _ingredientControllers.removeAt(index);
                                  });
                                }
                              },
                              child: Container(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.2,
                                      child: TextField(
                                        controller: _ingredientControllers[index][0],
                                        decoration: InputDecoration(
                                          labelText: 'Amount',
                                          labelStyle: TextStyle(
                                            color: color1,
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: color5),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontSize: fontSize2(context),
                                          color: color5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        cursorColor: color5,
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.5,
                                      child: TextField(
                                        controller: _ingredientControllers[index][1],
                                        decoration: InputDecoration(
                                          labelText: 'Ingredient Name',
                                          labelStyle: TextStyle(
                                            color: color1,
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: color5),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontSize: fontSize2(context),
                                          color: color5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        cursorColor: color5,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(padding: EdgeInsets.all(10)),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _ingredientControllers.add([
                                  TextEditingController(),
                                  TextEditingController(),
                                ]);
                              });
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  return states.contains(MaterialState.pressed) ||
                                          states.contains(MaterialState.hovered)
                                      ? color3
                                      : color2;
                                },
                              ),
                            ),
                            child: Text(
                              'Add ingredient',
                              style: TextStyle(
                                color: color5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(20)),
                  Container(                  
                    decoration: BoxDecoration(
                      color: color3,
                      borderRadius: const BorderRadius.all(Radius.circular(10))
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Steps',
                        style: TextStyle(
                          fontSize: fontSize3(context),
                          fontWeight: FontWeight.w700,
                          color: color1
                        ),
                      )
                    )
                  ),
                  Padding(padding: EdgeInsets.all(20)),
                  Container(
                    decoration: BoxDecoration(
                      color: color3,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _stepsControllers.length,
                            itemBuilder: (context, index) => Dismissible(
                              direction: DismissDirection.endToStart,
                              key: UniqueKey(),
                              background: Container(
                                decoration: BoxDecoration(
                                  color: color4,
                                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                                ),
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: Icon(
                                  Icons.delete_forever,
                                  color: color1,
                                ),
                              ),
                              confirmDismiss: (DismissDirection direction) {
                                return Future<bool?>.value(_stepsControllers.length > 1);
                              },
                              onDismissed: (DismissDirection direction) {
                                if (_stepsControllers.length > 1) {
                                  setState(() {
                                    _stepsControllers.removeAt(index);
                                  });
                                }
                              },
                              child: Container(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Text(
                                        (index +1).toString(),
                                        style: TextStyle(
                                          fontSize: fontSize3(context),
                                          fontWeight: FontWeight.w800,
                                          color: color1
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.6,
                                      child: TextField(
                                        maxLines: null,
                                        controller: _stepsControllers[index],
                                        decoration: InputDecoration(
                                          labelText: 'Step Instruction',
                                          labelStyle: TextStyle(
                                            color: color1,
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: color5),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontSize: fontSize2(context),
                                          color: color5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        cursorColor: color5,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(padding: EdgeInsets.all(10)),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _stepsControllers.add(TextEditingController());
                              });
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  return states.contains(MaterialState.pressed) ||
                                          states.contains(MaterialState.hovered)
                                      ? color3
                                      : color2;
                                },
                              ),
                            ),
                            child: Text(
                              'Add Step',
                              style: TextStyle(
                                color: color5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(20)),
                  TextButton(
                    onPressed: () {
                      setState(() async {
                        if(controllers.any((controller) => controller.text.isEmpty) || _ingredientControllers.any((list) => list.any((controller) => controller.text.isEmpty)) || _stepsControllers.any((controller) => controller.text.isEmpty)) {
                          _showMessage(context, 'Please fill out all the fields.');
                        } else {
                          Recipe recipe = Recipe(user_id: _user.id!, title: controllers[0].text, description: controllers[4].text, filter1: controllers[1].text, filter2: controllers[2].text, filter3: controllers[3].text, servings: int.parse(controllers[5].text), prepTime: int.parse(controllers[6].text), cookTime: int.parse(controllers[7].text));
                          int recipeId = await dbHelper.insertRecipe(recipe);
                          for(int i = 0; i < _ingredientControllers.length; i++) {
                            Ingredient ingredient = Ingredient(recipe_id: recipeId, ingredient: _ingredientControllers[i][1].text, amount: _ingredientControllers[i][0].text);
                            dbHelper.insertIngredient(ingredient);
                          }
                          for(int i = 0; i < _stepsControllers.length; i++) {
                            Stage stage = Stage(recipe_id: recipeId, num: i+1, info: _stepsControllers[i].text);
                            dbHelper.insertStep(stage);
                          }
                          _showMessage(context, 'Recipe successfully created!');
                          _router.go('/profile');
                        }
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          return states.contains(MaterialState.pressed) ||
                                states.contains(MaterialState.hovered)
                              ? color3
                              : color2;
                        },
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Create Recipe',
                        style: TextStyle(
                          color: color5,
                          fontSize: fontSize3(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  )
                ],
              ),
            )
        )
      )
    );
  }
}

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {

  @override
  Widget build(context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color3,
        title: Text(
          'My Feed',
          style: TextStyle(
            fontSize: fontSize4(context),
            fontWeight: FontWeight.w900,
            color: color1
          ),
        )
      ),
      backgroundColor: color4,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _recipeListView(dbHelper.retrieveRecipes())
      ),
    );
  }
}

class RecipeBookPage extends StatefulWidget {
  const RecipeBookPage({super.key});

  @override
  State<RecipeBookPage> createState() => _RecipeBookPageState();
}

class _RecipeBookPageState extends State<RecipeBookPage> {

  @override
  Widget build(context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color3,
        title: Text(
          'My Recipe Book',
          style: TextStyle(
            fontSize: fontSize4(context),
            fontWeight: FontWeight.w900,
            color: color1
          ),
        )
      ),
      backgroundColor: color4,
      body: Padding( 
        padding: EdgeInsets.all(20),
        child: Center(
          child: Column (
          children: [
            Padding(padding: EdgeInsets.all(10)),
            TextButton(
              onPressed: () {
                setState(() {
                 _router.go('/createRecipe');
                });
              },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      return states.contains(MaterialState.pressed) ||
                        states.contains(MaterialState.hovered)
                          ? color2
                          : color1;
                        },
                      ),
                  ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  'Create Recipe',
                  style: TextStyle(
                    color: color3,
                    fontSize: fontSize3(context)
                  ),
                ),
              ),
            ),
            Padding(padding: EdgeInsets.all(20),),
            _userSavedRecipes.length != 0 ?
                    Expanded(
                      child: _recipeListView(dbHelper.getSavedRecipesForUser(_user.id!)
                    )) :
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height *0.15),
                      child: Text(
                        'There are no recipes saved. \nGo to your Feed to find some!',
                        style: TextStyle(
                          fontSize: fontSize3(context),
                          color: color2
                        ),
                        textAlign: TextAlign.center,
                      )
                    )
              ],
            ),
          )
      )
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  TextEditingController searchController = TextEditingController();
  @override
  Widget build(context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color3,
        title: Text(
          'My Cart',
          style: TextStyle(
            fontSize: fontSize4(context),
            fontWeight: FontWeight.w900,
            color: color1
          ),
        )
      ),
      backgroundColor: color4,
      body: Padding(
        padding: EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: _cartWidget()
        )
      ) 
    );
  }
  _cartWidget () {
    return FutureBuilder(
          future: dbHelper.getIngredientsInCart(_user.id!),
          builder: (BuildContext context, AsyncSnapshot<List<Ingredient>> snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              _userCart = snapshot.data!;
              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _userCart.length,
                itemBuilder: (context, index) => Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() {
                      dbHelper.removeFromCart(_user.id!, _userCart[index].id!);
                    });
                  },
                  background: Container(
                    decoration: BoxDecoration(
                      color: color3,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Icon(
                      Icons.delete_forever,
                      color: color1,
                    ),
                  ),
                  child: GestureDetector(
                    onDoubleTap: () async {
                      _recipe = (await dbHelper.getRecipeByID(_userCart[index].recipe_id))!;
                      _router.go('/specificRecipe');
                    },
                    child: Padding( 
                      padding: EdgeInsets.all(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color5,
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Text(
                                _userCart[index].ingredient,
                                style: TextStyle(
                                  fontSize: fontSize3(context),
                                  fontWeight: FontWeight.w500,
                                  color: color2
                                ),
                              )
                            ],
                          )      
                        )
                      )
                    )
                  )
                )
              );
            } else {
              return Center(
                child: Text(
                  'There are no ingredients saved.\nAdd some from a recipe!',
                  style: TextStyle(
                    fontSize: fontSize3(context),
                    color: color2
                  ),
                  textAlign: TextAlign.center,
                )
              );
            }
          }
        );
  }
}


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _bioController = TextEditingController();
  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            fontSize: fontSize4(context),
            fontWeight: FontWeight.w900,
            color: color1
          ),
        ),
        backgroundColor: color3,
      ),
      backgroundColor: color4,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color3,
                  borderRadius: BorderRadius.circular(10)
                ),
                width: MediaQuery.of(context).size.width,
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: color2,
                          borderRadius: BorderRadius.circular(5)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            _user.username,
                            style: TextStyle(
                              fontSize: fontSize4(context),
                              fontWeight: FontWeight.w600,
                              color: color4
                            ),
                          )
                        )
                      ),
                      const Padding(padding: EdgeInsets.all(10),),
                      Container(
                        decoration: BoxDecoration(
                          color: color2,
                          borderRadius: BorderRadius.circular(5)
                        ),
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: GestureDetector(
                          onDoubleTap: () {
                            setState(() {
                              _bioController.text = _user.bio;
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: color4,
                                    title: Text(
                                      'Edit Bio',
                                      style: TextStyle(
                                        color: color2,
                                        fontSize: fontSize3(context),
                                        fontWeight: FontWeight.w800
                                      )
                                    ),
                                    content: TextField(
                                      autofocus: true,
                                      maxLines: null,
                                      controller: _bioController,
                                      decoration: InputDecoration(
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: color2),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: fontSize2(context),
                                        color: color2,
                                        fontWeight: FontWeight.w700
                                      ),
                                      cursorColor: color2,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        style: ButtonStyle(
                                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                            (Set<MaterialState> states) {
                                              return states.contains(MaterialState.pressed) ||
                                                states.contains(MaterialState.hovered)
                                              ? color2
                                              : color3;
                                            },
                                          ),
                                        ),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: fontSize2(context),
                                            fontWeight: FontWeight.w600,
                                            color: color1
                                          ),
                                        )
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          if(_bioController.text.isEmpty) {
                                            dbHelper.updateBio(_user.id!, 'No bio.');
                                          } else {
                                            dbHelper.updateBio(_user.id!, _bioController.text);
                                          }
                                          _user = (await dbHelper.getUserByID(_user.id!))!;
                                          Navigator.pop(context);
                                          setState(() {});
                                        },
                                        style: ButtonStyle(
                                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                            (Set<MaterialState> states) {
                                              return states.contains(MaterialState.pressed) ||
                                                states.contains(MaterialState.hovered)
                                              ? color2
                                              : color3;
                                            },
                                          ),
                                        ),
                                        child: Text(
                                          'Save',
                                          style: TextStyle(
                                            fontSize: fontSize2(context),
                                            fontWeight: FontWeight.w600,
                                            color: color1
                                          ),
                                        )
                                      )
                                    ],
                                  );
                                }
                              );
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                _user.bio,
                                style: TextStyle(
                                  color: color3,
                                  fontSize: fontSize3(context),
                                  fontWeight: FontWeight.w500
                                )
                              ),
                            )
                          )
                        )
                      ),
                    ],
                  )
                )
              ),
              const Padding(padding: EdgeInsets.all(10)),
              Container(
                decoration: BoxDecoration(
                  color: color3,
                  borderRadius: BorderRadius.circular(10)
                ),
                width: MediaQuery.of(context).size.width,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: color2,
                          borderRadius: BorderRadius.circular(5)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            'My Recipes',
                            style: TextStyle(
                              color: color4,
                              fontSize: fontSize3(context),
                              fontWeight: FontWeight.w800
                            )
                          )
                        )
                      ),
                      Padding(padding: EdgeInsets.all(5)),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Padding(
                          padding: const EdgeInsets.all(5), 
                          child: _userCreatedRecipes.isEmpty ?
                            Padding(
                              padding: const EdgeInsets.all(40),
                              child: Center(
                                child: Text(
                                  'You have not created any recipes yet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: color2,
                                    fontSize: fontSize2(context,),
                                    fontWeight: FontWeight.w500
                                  )
                                ),
                              )
                            ) :
                          _recipeListView(dbHelper.getRecipesByUser(_user.id!))
                        )
                      )
                    ],
                  )
                )
              ),
              const Padding(padding: EdgeInsets.all(10)),
              OutlinedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      return states.contains(MaterialState.pressed) ||
                            states.contains(MaterialState.hovered)
                        ? color2
                        : color3;
                    },
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: color4,
                        content: Text(
                          'Are you sure you want to log out?',
                          style: TextStyle(
                            color: color2
                          ),
                        ),
                        actions: [
                          OutlinedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  return states.contains(MaterialState.pressed) ||
                                        states.contains(MaterialState.hovered)
                                    ? color2
                                    : color3;
                                },
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'No',
                              style: TextStyle(
                                color: color1
                              ),
                            )
                          ),
                          OutlinedButton(
                            style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                return states.contains(MaterialState.pressed) ||
                                      states.contains(MaterialState.hovered)
                                  ? color2
                                  : color3;
                              },
                            ),
                          ),
                            onPressed: () {
                              _router.go('/login');
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Yes',
                              style: TextStyle(
                                color: color1
                              )
                            )
                          )
                        ], 
                      );
                    }
                  );
                },
                child: Text(
                  'Log out',
                  style: TextStyle(
                    color: color1,
                    fontSize: fontSize2(context),
                    fontWeight: FontWeight.w800
                  ),
                )
              )
            ]
          ),
        )
      )
    );
  }
}

Future<int> addUser() async {
  return await dbHelper.insertUser(_user);
} 

Future<String> getCreator() async {
  return (await dbHelper.getUserByID((await dbHelper.getRecipeByID(_recipe.id!))!.user_id))!.username;
}