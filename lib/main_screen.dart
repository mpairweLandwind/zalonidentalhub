import 'package:flutter/material.dart';
import 'package:zalonidentalhub/models/cart_model.dart';
//import 'package:zalonidentalhub/models/cart_model.dart';
import 'package:zalonidentalhub/screens/account_screen.dart';
import 'package:zalonidentalhub/screens/cart_screen.dart';
import 'package:zalonidentalhub/screens/category_screen.dart';
import 'package:zalonidentalhub/screens/home_screen.dart';



class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = [
    const HomeScreen(),
    const CategoriesScreen(),
     CartScreen(cartItems: const [], cartTotal: 0, cart: Cart(), user: null,),
  
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      // //  title: const Text('Main App'),
      // ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,        
        selectedItemColor: const Color.fromARGB(255, 21, 104, 172),
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        iconSize: 28,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),          
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories '),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined ), label: 'Cart'),         
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_sharp), label: 'Profile'),
        ],
       
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
