
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProductCategoriesScreen extends StatefulWidget {
  const ProductCategoriesScreen({super.key});

  @override
  _ProductCategoriesScreenState createState() =>
      _ProductCategoriesScreenState();
}

class _ProductCategoriesScreenState extends State<ProductCategoriesScreen> {
  List<String> myCategories = [];
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  bool isLoading = true;
  String selectedCategory = "All";
  String searchQuery = "";
  bool isAscending = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchCategoryProducts("All");
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text;
        filterAndSortProducts();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Fetch category list
  Future<void> fetchCategories() async {
    Uri url = Uri.parse("https://dummyjson.com/products");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)["products"];
        final List<String> fetchedCategories = ["All"];

        for (var product in data) {
          final String category = product["category"];
          if (!fetchedCategories.contains(category)) {
            fetchedCategories.add(category);
          }
        }
        setState(() {
          isLoading = false;
          myCategories = fetchedCategories;
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch category items
  Future<void> fetchCategoryProducts(String category) async {
    Uri url = Uri.parse("https://dummyjson.com/products");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)["products"];
        final List<dynamic> categoryProducts = [];

        for (var product in data) {
          final String productCategory = product["category"];
          if (category == "All" || productCategory == category) {
            categoryProducts.add(product);
          }
        }
        setState(() {
          selectedCategory = category;
          products = categoryProducts;
          filterAndSortProducts();
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print(e);
    }
  }

  void filterAndSortProducts() {
    setState(() {
      filteredProducts = products
          .where((product) => product["title"]
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();

      filteredProducts.sort((a, b) {
        if (isAscending) {
          return a["price"].compareTo(b["price"]);
        } else {
          return b["price"].compareTo(a["price"]);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Separate Category From API"),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search products...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<String>(
                      value: selectedCategory,
                      items: myCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        fetchCategoryProducts(value ?? "All");
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      ),
                      onPressed: () {
                        setState(() {
                          isAscending = !isAscending;
                          filterAndSortProducts();
                        });
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ListTile(
                        leading: Container(
                          height: 70,
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                                image: NetworkImage(
                                  product["thumbnail"],
                                ),
                                fit: BoxFit.cover),
                          ),
                        ),
                        title: Text(
                          product["title"],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text("\$${product['price']}"),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
